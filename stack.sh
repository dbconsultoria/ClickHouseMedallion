#!/usr/bin/env bash
# Garante que o script use o bash do sistema, independente de onde está instalado

set -euo pipefail
# -e  → aborta em qualquer comando que retorne erro
# -u  → aborta se usar variável não definida
# -o pipefail → propaga falha em pipes (ex: cmd1 | cmd2 falha se cmd1 falhar)

# ─── Colors ───────────────────────────────────────────────────────────────────
RED='\033[0;31m'      # vermelho — erros
GREEN='\033[0;32m'    # verde — sucesso
YELLOW='\033[1;33m'   # amarelo — avisos
CYAN='\033[0;36m'     # ciano — informação
BOLD='\033[1m'        # negrito — títulos
RESET='\033[0m'       # reseta todos os atributos de cor

# ─── Logging ──────────────────────────────────────────────────────────────────
# $* expande todos os argumentos como uma única string separada por espaços
log_info()    { echo -e "${CYAN}[INFO]${RESET}  $*"; }           # mensagem informativa
log_success() { echo -e "${GREEN}[OK]${RESET}    $*"; }          # operação concluída com sucesso
log_warn()    { echo -e "${YELLOW}[WARN]${RESET}  $*"; }         # aviso não-fatal
log_error()   { echo -e "${RED}[ERROR]${RESET} $*" >&2; }       # erro — redireciona para stderr

# ─── Paths ────────────────────────────────────────────────────────────────────
# Resolve o diretório real do script, independente de onde é chamado
SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"

CH_COMPOSE="${SCRIPT_DIR}/clickhouse/docker-compose.yml"   # compose do ClickHouse
AB_COMPOSE="${SCRIPT_DIR}/airbyte/docker-compose.yml"      # compose do Airbyte
DBT_DIR="${SCRIPT_DIR}/dbt"                                # raiz do projeto dbt
DBT_VENV="${DBT_DIR}/.venv"                                # virtualenv Python do dbt

CLICKHOUSE_HTTP="http://localhost:8123"          # HTTP interface do ClickHouse
AIRBYTE_API="http://localhost:8001/api/v1/health" # endpoint de health da API do Airbyte
AIRBYTE_UI="http://localhost:8000"               # interface web do Airbyte

# ─── Wait helpers ─────────────────────────────────────────────────────────────

wait_for_healthy() {
    local container="$1"          # nome do container Docker a verificar
    local timeout="${2:-60}"      # tempo máximo de espera em segundos (padrão: 60)
    local elapsed=0               # contador de segundos decorridos
    local interval=3              # intervalo entre verificações em segundos

    while [[ $elapsed -lt $timeout ]]; do
        local status
        # Lê o estado do health check do container via Docker inspect
        # || echo "not_found" evita falha do set -e se o container não existir
        status=$(docker inspect --format='{{.State.Health.Status}}' "$container" 2>/dev/null || echo "not_found")

        if [[ "$status" == "healthy" ]]; then
            printf "\r\033[K"   # \r volta ao início da linha; \033[K apaga até o fim
            log_success "${container} está saudável"
            return 0            # sai da função com sucesso
        fi

        # Atualiza o contador na mesma linha sem avançar para a próxima (\r)
        printf "\r${CYAN}[INFO]${RESET}  Aguardando ${container} ficar healthy... (%ds)" "$elapsed"
        sleep "$interval"                          # aguarda antes da próxima verificação
        elapsed=$((elapsed + interval))            # incrementa o contador
    done

    printf "\r\033[K"           # limpa a linha do contador antes de imprimir o erro
    log_error "${container} não ficou healthy em ${timeout}s."
    log_error "Diagnóstico: docker logs ${container}"
    return 1                    # sai com falha — set -e vai propagar para o chamador
}

wait_for_http() {
    local url="$1"              # URL a verificar
    local timeout="${2:-120}"   # tempo máximo de espera em segundos (padrão: 120)
    local elapsed=0             # contador de segundos decorridos
    local interval=5            # intervalo entre verificações em segundos

    while [[ $elapsed -lt $timeout ]]; do
        local code
        # -s silencia progress bar; -o /dev/null descarta o body; -w imprime só o HTTP code
        # --max-time 3 evita que curl trave esperando uma conexão lenta
        # || echo "000" evita falha do set -e em caso de erro de rede
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 3 "$url" 2>/dev/null || echo "000")

        if [[ "$code" == "200" ]]; then
            printf "\r\033[K"
            log_success "Airbyte está pronto"
            return 0
        fi

        printf "\r${CYAN}[INFO]${RESET}  Aguardando Airbyte API... (%ds)" "$elapsed"
        sleep "$interval"
        elapsed=$((elapsed + interval))
    done

    printf "\r\033[K"
    log_error "Airbyte não respondeu em ${timeout}s."
    log_error "Diagnóstico: docker logs airbyte-server"
    return 1
}

# ─── Prerequisite check ───────────────────────────────────────────────────────

check_prerequisites() {
    log_info "Verificando pré-requisitos..."
    local failed=0    # flag: 1 se algum pré-requisito estiver ausente

    # Verifica cada binário necessário; acumula falhas em vez de abortar imediatamente
    for cmd in docker curl; do
        if command -v "$cmd" &>/dev/null; then   # &>/dev/null descarta stdout e stderr
            log_success "${cmd} encontrado"
        else
            log_error "${cmd} não encontrado — instale antes de continuar"
            failed=1
        fi
    done

    # Verifica o plugin docker compose v2 (diferente do docker-compose v1 standalone)
    if docker compose version &>/dev/null; then
        log_success "docker compose encontrado"
    else
        log_error "docker compose (plugin v2) não encontrado"
        failed=1
    fi

    # Aborta somente após verificar todos os pré-requisitos, listando todos os ausentes
    [[ $failed -eq 0 ]] || { log_error "Pré-requisitos ausentes. Abortando."; exit 1; }
}

# ─── up ───────────────────────────────────────────────────────────────────────

cmd_up() {
    check_prerequisites    # valida docker, curl e docker compose antes de qualquer coisa

    log_info "Iniciando ClickHouse..."
    docker compose -f "$CH_COMPOSE" up -d    # -d = detached (segundo plano)
    wait_for_healthy "clickhouse" 60         # aguarda health check passar (máx 60s)

    log_info "Criando database bronze..."
    local response
    # Envia SQL via HTTP API do ClickHouse (POST com body = query SQL)
    response=$(curl -s "$CLICKHOUSE_HTTP" --data "CREATE DATABASE IF NOT EXISTS bronze")
    # ClickHouse retorna body vazio no sucesso; em erro retorna "Code: X. DB::Exception..."
    if echo "$response" | grep -q "Code:\|Exception"; then
        log_warn "Resposta inesperada do ClickHouse: ${response}"
    else
        log_success "Database bronze criado"
    fi

    log_info "Iniciando Airbyte (pode levar 30-60s)..."
    docker compose -f "$AB_COMPOSE" up -d       # sobe os 7 serviços do Airbyte
    wait_for_http "$AIRBYTE_API" 120            # aguarda API responder HTTP 200 (máx 120s)

    echo ""
    echo -e "${BOLD}Stack ativa:${RESET}"
    echo -e "  Airbyte UI      → ${CYAN}${AIRBYTE_UI}${RESET}"
    echo -e "  Airbyte API     → ${CYAN}${AIRBYTE_API}${RESET}"
    echo -e "  ClickHouse HTTP → ${CYAN}${CLICKHOUSE_HTTP}${RESET}"
    echo -e "  SQL Playground  → ${CYAN}${CLICKHOUSE_HTTP}/play${RESET}"
    echo ""
}

# ─── down ─────────────────────────────────────────────────────────────────────

cmd_down() {
    log_info "Derrubando Airbyte..."
    docker compose -f "$AB_COMPOSE" down    # Airbyte primeiro: depende de medallion_net do ClickHouse
    log_success "Airbyte parado"

    log_info "Derrubando ClickHouse..."
    docker compose -f "$CH_COMPOSE" down    # ClickHouse por último: dono da rede medallion_net
    log_success "ClickHouse parado"
}

# ─── restart ──────────────────────────────────────────────────────────────────

cmd_restart() {
    cmd_down    # derruba na ordem correta
    echo ""
    cmd_up      # sobe na ordem correta com todos os health checks
}

# ─── status ───────────────────────────────────────────────────────────────────

cmd_status() {
    echo -e "${BOLD}── ClickHouse ──────────────────────────────────────────────────${RESET}"
    docker compose -f "$CH_COMPOSE" ps    # lista containers e estado do ClickHouse
    echo ""
    echo -e "${BOLD}── Airbyte ─────────────────────────────────────────────────────${RESET}"
    docker compose -f "$AB_COMPOSE" ps    # lista containers e estado do Airbyte
}

# ─── health ───────────────────────────────────────────────────────────────────

cmd_health() {
    echo -e "${BOLD}── Health Check ────────────────────────────────────────────────${RESET}"

    # Array de entradas no formato "Nome|URL" — o pipe é o separador
    local -a entries=(
        "ClickHouse HTTP|${CLICKHOUSE_HTTP}"
        "ClickHouse Playground|${CLICKHOUSE_HTTP}/play"
        "Airbyte UI|${AIRBYTE_UI}"
        "Airbyte API|${AIRBYTE_API}"
    )

    for entry in "${entries[@]}"; do
        local name="${entry%%|*}"    # tudo antes do primeiro pipe = nome
        local url="${entry##*|}"     # tudo depois do último pipe = URL
        local code
        # --max-time 5 evita espera longa por serviços que não respondem
        code=$(curl -s -o /dev/null -w "%{http_code}" --max-time 5 "$url" 2>/dev/null || echo "000")

        if [[ "$code" == "200" ]]; then
            # %-24s alinha o nome em 24 caracteres para formatação em colunas
            printf "  ${GREEN}✓${RESET}  %-24s ${CYAN}%s${RESET}\n" "$name" "$url"
        else
            printf "  ${RED}✗${RESET}  %-24s ${CYAN}%s${RESET}  ${RED}(HTTP %s)${RESET}\n" "$name" "$url" "$code"
        fi
    done

    echo ""
}

# ─── dbt ──────────────────────────────────────────────────────────────────────

cmd_dbt() {
    # Cria o virtualenv somente se ainda não existir (idempotente)
    if [[ ! -d "$DBT_VENV" ]]; then
        log_info "Ambiente virtual não encontrado. Criando em ${DBT_VENV}..."
        python3 -m venv "$DBT_VENV"    # cria venv isolado para não poluir o Python do sistema
        log_success "Venv criado"

        log_info "Instalando dbt-core e dbt-clickhouse..."
        "${DBT_VENV}/bin/pip" install --quiet --upgrade pip             # atualiza pip antes
        "${DBT_VENV}/bin/pip" install --quiet dbt-core dbt-clickhouse   # instala dependências
        log_success "Dependências instaladas"
    fi

    local dbt="${DBT_VENV}/bin/dbt"    # caminho absoluto para o binário dbt do venv
    local failed=0                      # flag de falha do pipeline

    # Subshell ( ... ) isola o cd: o diretório corrente do script principal não muda
    (
        cd "$DBT_DIR"    # dbt precisa do dbt_project.yml no diretório corrente

        log_info "Executando dbt debug..."
        # Valida conexão com ClickHouse e integridade do profiles.yml antes de rodar
        if "$dbt" debug --profiles-dir . ; then
            log_success "dbt debug OK"
        else
            log_error "dbt debug falhou — verifique conexão com ClickHouse e profiles.yml"
            exit 1    # exit dentro do subshell — não encerra o script principal
        fi

        log_info "Executando dbt run (Silver)..."
        # Materializa as 5 tabelas Silver (limpeza e enriquecimento da Bronze)
        if "$dbt" run --profiles-dir . --select silver; then
            log_success "Silver materializada"
        else
            log_error "dbt run Silver falhou"
            exit 1
        fi

        log_info "Executando dbt run (Gold)..."
        # Materializa as 5 tabelas Gold (marts analíticos sobre a Silver)
        if "$dbt" run --profiles-dir . --select gold; then
            log_success "Gold materializada"
        else
            log_error "dbt run Gold falhou"
            exit 1
        fi

        log_info "Executando dbt test..."
        # Roda os 48 testes de qualidade (not_null, unique, relationships)
        if "$dbt" test --profiles-dir . ; then
            log_success "Todos os testes passaram"
        else
            log_error "dbt test falhou — verifique qualidade dos dados"
            exit 1
        fi
    ) || { failed=1; }    # captura falha do subshell sem deixar set -e abortar aqui

    echo ""
    if [[ $failed -eq 0 ]]; then
        log_success "Pipeline dbt concluído com sucesso (Silver + Gold)"
    else
        log_error "Pipeline dbt concluído com falhas — veja os erros acima"
        exit 1
    fi
}

# ─── logs ─────────────────────────────────────────────────────────────────────

cmd_logs() {
    local service="${1:-}"    # serviço opcional; vazio = mostrar os principais

    if [[ -n "$service" ]]; then
        # Verifica se o serviço pertence ao compose do ClickHouse; senão assume Airbyte
        if docker compose -f "$CH_COMPOSE" ps --services 2>/dev/null | grep -qx "$service"; then
            docker compose -f "$CH_COMPOSE" logs --tail=100 -f "$service"
        else
            docker compose -f "$AB_COMPOSE" logs --tail=100 -f "$service"
        fi
    else
        log_info "Logs: clickhouse, airbyte-server, airbyte-worker  (Ctrl+C para sair)"
        # trap garante que os processos em background sejam encerrados com Ctrl+C
        # sem o trap, os processos filho ficam como órfãos no terminal
        trap 'kill $(jobs -p) 2>/dev/null; exit 0' INT TERM
        docker compose -f "$CH_COMPOSE" logs --tail=50 -f clickhouse &           # & = background
        docker compose -f "$AB_COMPOSE" logs --tail=50 -f airbyte-server airbyte-worker &
        wait    # aguarda todos os processos em background encerrarem
    fi
}

# ─── reset ────────────────────────────────────────────────────────────────────

cmd_reset() {
    echo ""
    echo -e "${RED}${BOLD}  ATENÇÃO: esta operação remove todos os volumes.${RESET}"
    echo -e "${RED}  Todos os dados do ClickHouse e do Airbyte serão perdidos.${RESET}"
    echo ""
    read -r -p "  Confirma o reset completo? [y/N] " confirm    # -r evita que \ seja interpretado

    # ${confirm,,} converte a resposta para minúsculas (bash 4+)
    if [[ "${confirm,,}" != "y" ]]; then
        log_info "Reset cancelado."
        exit 0
    fi

    echo ""
    log_warn "Removendo Airbyte e volumes..."
    docker compose -f "$AB_COMPOSE" down -v || true    # || true evita abort se já estiver parado

    log_warn "Removendo ClickHouse e volumes..."
    docker compose -f "$CH_COMPOSE" down -v || true    # -v remove os volumes nomeados junto

    log_success "Volumes removidos"
    echo ""
    cmd_up    # reinicia a stack do zero após limpeza
}

# ─── help ─────────────────────────────────────────────────────────────────────

cmd_help() {
    echo ""
    echo -e "${BOLD}  ClickHouse Medallion Architecture — stack.sh${RESET}"
    echo ""
    echo -e "  ${CYAN}./stack.sh up${RESET}               Sobe a stack completa (ClickHouse + Airbyte)"
    echo -e "  ${CYAN}./stack.sh down${RESET}             Derruba a stack"
    echo -e "  ${CYAN}./stack.sh restart${RESET}          Reinicia a stack"
    echo -e "  ${CYAN}./stack.sh status${RESET}           Status dos containers"
    echo -e "  ${CYAN}./stack.sh health${RESET}           Verifica saúde de todos os endpoints"
    echo -e "  ${CYAN}./stack.sh dbt${RESET}              Executa pipeline dbt (debug → Silver → Gold → test)"
    echo -e "  ${CYAN}./stack.sh logs [serviço]${RESET}   Logs em tempo real (padrão: clickhouse + airbyte-server + airbyte-worker)"
    echo -e "  ${CYAN}./stack.sh reset${RESET}            Remove volumes e reinicia ${RED}(DESTRUTIVO)${RESET}"
    echo -e "  ${CYAN}./stack.sh help${RESET}             Esta mensagem"
    echo ""
}

# ─── Entrypoint ───────────────────────────────────────────────────────────────

main() {
    local cmd="${1:-help}"    # primeiro argumento; padrão = help se nenhum for passado

    case "$cmd" in
        up)             cmd_up ;;
        down)           cmd_down ;;
        restart)        cmd_restart ;;
        status)         cmd_status ;;
        health)         cmd_health ;;
        dbt)            cmd_dbt ;;
        logs)           cmd_logs "${2:-}" ;;    # passa segundo argumento (serviço opcional)
        reset)          cmd_reset ;;
        help|--help|-h) cmd_help ;;             # aceita help, --help e -h
        *)
            log_error "Subcomando desconhecido: '${cmd}'"
            cmd_help
            exit 1
            ;;
    esac
}

main "$@"    # $@ passa todos os argumentos do script para main, preservando espaços
