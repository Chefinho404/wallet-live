-- Dinheiro é guardado em centavos (inteiro) para evitar erros de arredondamento.
CREATE TABLE ativos (
    id                   BIGSERIAL PRIMARY KEY,
    usuario_id           BIGINT      NOT NULL REFERENCES usuarios (id) ON DELETE CASCADE,
    ticker               TEXT        NOT NULL,
    nome                 TEXT        NOT NULL,
    tipo                 TEXT        NOT NULL,
    quantidade           BIGINT      NOT NULL CHECK (quantidade > 0),
    preco_medio_centavos BIGINT      NOT NULL CHECK (preco_medio_centavos > 0),
    criado_em            TIMESTAMPTZ NOT NULL DEFAULT now(),
    atualizado_em        TIMESTAMPTZ NOT NULL DEFAULT now(),
    UNIQUE (usuario_id, ticker)
);

CREATE INDEX ativos_usuario_idx ON ativos (usuario_id);
