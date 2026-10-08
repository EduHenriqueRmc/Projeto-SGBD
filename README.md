# AV3 — Criação e Povoamento · Clínica Veterinária (Grupo 5)

Scripts SQL (Oracle) gerados a partir do **Esquema Relacional Normalizado da AV2**.

## Como executar (Oracle Live SQL)

1. Rode `01_criacao.sql` inteiro. O bloco inicial apaga as tabelas e sequences, se já existirem; por isso o script pode ser executado mais de uma vez.
2. Rode `02_povoamento.sql` inteiro. Ele termina com `COMMIT`.

> Sempre rode os dois **em sequência e a partir do zero**. As FKs do povoamento usam os ids 1, 2, 3… gerados pelas sequences. Se o povoamento for interrompido no meio e executado de novo sem rodar a criação, as sequences continuam de onde pararam e os ids deixam de bater.

## Checklist da entrega

| Item obrigatório | Onde | Quantidade |
|---|---|---|
| `CREATE TABLE` | 01_criacao.sql | 15 tabelas |
| `INSERT INTO` | 02_povoamento.sql | 716 registros |
| Cláusula `CONSTRAINT` em `CREATE TABLE` | 01_criacao.sql | 57 constraints nomeadas (PK, FK, UNIQUE, CHECK) |
| `CREATE SEQUENCE` | 01_criacao.sql | 6 sequences (matrícula, consulta, procedimento, prescrição, medicamento, diagnóstico) |
| Cláusula `CHECK` em `CREATE TABLE` | 01_criacao.sql | 19 checks |

## Volume do povoamento

| Tabela | Registros |
|---|---|
| Localidade | 18 |
| Pessoa | 42 (15 funcionários + 27 clientes) |
| Telefone_Pessoa | 65 |
| Funcionario / Veterinario / Atendente | 15 / 8 / 7 |
| Cliente | 27 |
| Pet | 48 |
| Recepciona | 78 |
| Diagnostico | 20 |
| Medicamento | 24 |
| Consulta | 92 (Realizada, Cancelada e Agendada) |
| Procedimento | 113 |
| Prescricao | 58 |
| Item_prescricao | 101 |

## Regras do modelo respeitadas nos dados

- **Especializações totais e disjuntas:** toda pessoa é cliente **ou** funcionário, e todo funcionário é veterinário **ou** atendente.
- **Pet (entidade fraca):** PK = (cpf_cliente, num), e todo cliente tem ao menos um pet.
- **Recepciona (temporal):** todo cliente foi recepcionado ao menos uma vez. Há pares atendente–cliente que se repetem em datas diferentes, diferenciados por `data_inicio`.
- **Supervisiona:** a diretora clínica não tem supervisor; a coordenadora de recepção supervisiona os atendentes.
- **Coerência clínica:**
  - Animais exóticos são atendidos pela veterinária de silvestres.
  - Medicamentos e procedimentos são compatíveis com cada diagnóstico.
  - O tipo de receita (Simples, Antimicrobiano, Controle Especial) e a validade acompanham os medicamentos.
- **Datas coerentes:**
  - Consultas futuras ficam como `Agendada`.
  - Procedimentos e prescrições só existem em consultas `Realizada`.
  - A validade da receita é posterior à consulta.
  - Ninguém atende antes da própria admissão.
- **Trata (parcial):** existe item de prescrição sem diagnóstico vinculado (`id_diagnostico` nulo).

## Alteração em relação à AV2 (reenviar o documento da AV2 com este ajuste)

**Medicamento recebeu o atributo `Nome`.** Na AV1 o nome havia sido removido, e o catálogo ficou identificado apenas por id e fabricante. Ao povoar o banco, isso se mostrou insuficiente: as perguntas e relatórios previstos ("quais medicamentos foram prescritos para um diagnóstico…") precisam exibir o nome do medicamento. Foi adicionada também a restrição `UNIQUE (nome, fabricante)`.

Trechos a atualizar no documento da AV2:

- **Minimundo 3.9:** acrescentar `Nome` aos atributos de Medicamento e ajustar a frase da seção 7.4 ("removido o atributo Nome").
- **Etapa 1, Relações mapeadas e Esquema final:** `Medicamento(Id_medicamento, Nome, Fabricante, Quantidade_estoque)`.
- **Normalização:** nada muda. Nome depende apenas de Id_medicamento, e a relação continua na BCNF.

Também convém incluir `Nome` no diagrama EER (elipse ligada a Medicamento).
