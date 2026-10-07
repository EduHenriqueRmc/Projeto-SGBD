--Script para poder reexecutar do zero
BEGIN
    FOR t IN (SELECT table_name FROM user_tables
              WHERE table_name IN ('ITEM_PRESCRICAO', 'PRESCRICAO', 'PROCEDIMENTO',
                                   'CONSULTA', 'RECEPCIONA', 'PET', 'ATENDENTE',
                                   'VETERINARIO', 'FUNCIONARIO', 'CLIENTE',
                                   'TELEFONE_PESSOA', 'PESSOA', 'LOCALIDADE',
                                   'MEDICAMENTO', 'DIAGNOSTICO'))
    LOOP
        EXECUTE IMMEDIATE 'DROP TABLE ' || t.table_name || ' CASCADE CONSTRAINTS';
    END LOOP;

    FOR s IN (SELECT sequence_name FROM user_sequences
              WHERE sequence_name IN ('SEQ_MATRICULA', 'SEQ_CONSULTA', 'SEQ_PROCEDIMENTO',
                                      'SEQ_PRESCRICAO', 'SEQ_MEDICAMENTO', 'SEQ_DIAGNOSTICO'))
    LOOP
        EXECUTE IMMEDIATE 'DROP SEQUENCE ' || s.sequence_name;
    END LOOP;
END;
/

--Sequences
CREATE SEQUENCE seq_matricula    START WITH 1001 INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_consulta     START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_procedimento START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_prescricao   START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_medicamento  START WITH 1    INCREMENT BY 1 NOCACHE;
CREATE SEQUENCE seq_diagnostico  START WITH 1    INCREMENT BY 1 NOCACHE;

--Tabelas
CREATE TABLE Localidade (
    cep     CHAR(8),
    rua     VARCHAR2(80) NOT NULL,
    cidade  VARCHAR2(50) NOT NULL,

    CONSTRAINT localidade_pk     PRIMARY KEY (cep),
    CONSTRAINT localidade_cep_ck CHECK (REGEXP_LIKE(cep, '^[0-9]{8}$'
    ))
);

CREATE TABLE Pessoa (
    cpf   CHAR(11),
    nome  VARCHAR2(80) NOT NULL,
    cep   CHAR(8)      NOT NULL,

    CONSTRAINT pessoa_pk     PRIMARY KEY (cpf),
    CONSTRAINT pessoa_cep_fk FOREIGN KEY (cep) REFERENCES Localidade (cep),
    CONSTRAINT pessoa_cpf_ck CHECK (REGEXP_LIKE(cpf, '^[0-9]{11}$'))
);

CREATE TABLE Telefone_Pessoa (
    cpf_pessoa  CHAR(11),
    numero      VARCHAR2(11),

    CONSTRAINT telefone_pessoa_pk     PRIMARY KEY (cpf_pessoa, numero),
    CONSTRAINT telefone_pessoa_fk     FOREIGN KEY (cpf_pessoa) REFERENCES Pessoa (cpf)
                                      ON DELETE CASCADE,
    CONSTRAINT telefone_pessoa_num_ck CHECK (REGEXP_LIKE(numero, '^[0-9]{10,11}$'))
);

CREATE TABLE Cliente (
    cpf_pessoa     CHAR(11),
    pref_contato   VARCHAR2(10) NOT NULL,
    data_cadastro  DATE DEFAULT SYSDATE NOT NULL,

    CONSTRAINT cliente_pk      PRIMARY KEY (cpf_pessoa),
    CONSTRAINT cliente_fk      FOREIGN KEY (cpf_pessoa) REFERENCES Pessoa (cpf)
                               ON DELETE CASCADE,
    CONSTRAINT cliente_pref_ck CHECK (pref_contato IN ('Telefone', 'WhatsApp', 'SMS'))
);

CREATE TABLE Funcionario (
    cpf_pessoa      CHAR(11),
    matricula       NUMBER(6)    NOT NULL,
    salario         NUMBER(8,2)  NOT NULL, 
    data_admissao   DATE         NOT NULL,
    situacao        VARCHAR2(10) NOT NULL,
    cpf_supervisor  CHAR(11),

    CONSTRAINT funcionario_pk           PRIMARY KEY (cpf_pessoa),
    CONSTRAINT funcionario_matricula_uk UNIQUE (matricula),
    CONSTRAINT funcionario_pessoa_fk    FOREIGN KEY (cpf_pessoa) REFERENCES Pessoa (cpf)
                                        ON DELETE CASCADE,
    CONSTRAINT funcionario_superv_fk    FOREIGN KEY (cpf_supervisor) REFERENCES Funcionario (cpf_pessoa),
    CONSTRAINT funcionario_salario_ck   CHECK (salario > 0),
    CONSTRAINT funcionario_situacao_ck  CHECK (situacao IN ('Ativo', 'Ferias', 'Afastado', 'Desligado')),
    CONSTRAINT funcionario_superv_ck    CHECK (cpf_supervisor IS NULL OR cpf_supervisor <> cpf_pessoa)
);

CREATE TABLE Veterinario (
    cpf_funcionario  CHAR(11),
    crmv             VARCHAR2(10) NOT NULL,
    especialidade    VARCHAR2(40) NOT NULL,

    CONSTRAINT veterinario_pk      PRIMARY KEY (cpf_funcionario),
    CONSTRAINT veterinario_crmv_uk UNIQUE (crmv),
    CONSTRAINT veterinario_fk      FOREIGN KEY (cpf_funcionario) REFERENCES Funcionario (cpf_pessoa)
                                   ON DELETE CASCADE,
    CONSTRAINT veterinario_crmv_ck CHECK (REGEXP_LIKE(crmv, '^[A-Z]{2}-[0-9]{4,6}$'))
);

CREATE TABLE Atendente (
    cpf_funcionario  CHAR(11),
    setor            VARCHAR2(15) NOT NULL,

    CONSTRAINT atendente_pk       PRIMARY KEY (cpf_funcionario),
    CONSTRAINT atendente_fk       FOREIGN KEY (cpf_funcionario) REFERENCES Funcionario (cpf_pessoa)
                                  ON DELETE CASCADE,
    CONSTRAINT atendente_setor_ck CHECK (setor IN ('Recepção', 'Agendamento'))
);

CREATE TABLE Pet (
    cpf_cliente  CHAR(11),
    num          NUMBER(3),
    nome         VARCHAR2(40)  NOT NULL,
    especie      VARCHAR2(10)  NOT NULL,
    raca         VARCHAR2(40)  NOT NULL,
    peso         NUMBER(6,3)   NOT NULL, 

    CONSTRAINT pet_pk         PRIMARY KEY (cpf_cliente, num),
    CONSTRAINT pet_cliente_fk FOREIGN KEY (cpf_cliente) REFERENCES Cliente (cpf_pessoa)
                              ON DELETE CASCADE,
    CONSTRAINT pet_num_ck     CHECK (num > 0),
    CONSTRAINT pet_peso_ck    CHECK (peso > 0),
    CONSTRAINT pet_especie_ck CHECK (especie IN ('Cão', 'Gato', 'Ave', 'Coelho', 'Roedor', 'Réptil'))
);

CREATE TABLE Recepciona (
    cpf_atendente  CHAR(11),
    cpf_cliente    CHAR(11),
    data_inicio    DATE,
    data_fim       DATE,

    CONSTRAINT recepciona_pk           PRIMARY KEY (cpf_atendente, cpf_cliente, data_inicio),
    CONSTRAINT recepciona_atendente_fk FOREIGN KEY (cpf_atendente) REFERENCES Atendente (cpf_funcionario),
    CONSTRAINT recepciona_cliente_fk   FOREIGN KEY (cpf_cliente) REFERENCES Cliente (cpf_pessoa)
                                       ON DELETE CASCADE,
    CONSTRAINT recepciona_periodo_ck   CHECK (data_fim IS NULL OR data_fim > data_inicio)
);

CREATE TABLE Consulta (
    id_consulta      NUMBER(6),
    cpf_cliente_pet  CHAR(11)     NOT NULL,
    num_pet          NUMBER(3)    NOT NULL,
    cpf_veterinario  CHAR(11)     NOT NULL,
    data             DATE         NOT NULL,
    horario          CHAR(5)      NOT NULL,
    situacao         VARCHAR2(10) NOT NULL,

    CONSTRAINT consulta_pk          PRIMARY KEY (id_consulta),
    CONSTRAINT consulta_pet_fk      FOREIGN KEY (cpf_cliente_pet, num_pet) REFERENCES Pet (cpf_cliente, num),
    CONSTRAINT consulta_vet_fk      FOREIGN KEY (cpf_veterinario) REFERENCES Veterinario (cpf_funcionario),
    CONSTRAINT consulta_agenda_uk   UNIQUE (cpf_veterinario, data, horario),
    CONSTRAINT consulta_horario_ck  CHECK (REGEXP_LIKE(horario, '^([01][0-9]|2[0-3]):[0-5][0-9]$')),
    CONSTRAINT consulta_situacao_ck CHECK (situacao IN ('Agendada', 'Realizada', 'Cancelada'))
);

CREATE TABLE Procedimento (
    id_procedimento  NUMBER(6),
    id_consulta      NUMBER(6)     NOT NULL,
    data             DATE          NOT NULL,
    descricao        VARCHAR2(120) NOT NULL,

    CONSTRAINT procedimento_pk          PRIMARY KEY (id_procedimento),
    CONSTRAINT procedimento_consulta_fk FOREIGN KEY (id_consulta) REFERENCES Consulta (id_consulta)
                                        ON DELETE CASCADE
);

CREATE TABLE Prescricao (
    id_prescricao  NUMBER(6),
    id_consulta    NUMBER(6)    NOT NULL,
    validade       DATE         NOT NULL,
    tipo_receita   VARCHAR2(20) NOT NULL,

    CONSTRAINT prescricao_pk          PRIMARY KEY (id_prescricao),
    CONSTRAINT prescricao_consulta_fk FOREIGN KEY (id_consulta) REFERENCES Consulta (id_consulta)
                                      ON DELETE CASCADE
);

CREATE TABLE Medicamento (
    id_medicamento      NUMBER(6),
    nome                VARCHAR2(60) NOT NULL,
    fabricante          VARCHAR2(40) NOT NULL,
    quantidade_estoque  NUMBER(6)    NOT NULL,

    CONSTRAINT medicamento_pk         PRIMARY KEY (id_medicamento),
    CONSTRAINT medicamento_nome_uk    UNIQUE (nome, fabricante),
    CONSTRAINT medicamento_estoque_ck CHECK (quantidade_estoque >= 0)
);

CREATE TABLE Diagnostico (
    id_diagnostico  NUMBER(6),
    descricao       VARCHAR2(80) NOT NULL,

    CONSTRAINT diagnostico_pk  PRIMARY KEY (id_diagnostico),
);

CREATE TABLE Item_prescricao (
    id_prescricao         NUMBER(6),
    id_medicamento        NUMBER(6),
    id_diagnostico        NUMBER(6),
    dosagem               VARCHAR2(30) NOT NULL,
    frequencia            VARCHAR2(40) NOT NULL,
    via_adm               VARCHAR2(15) NOT NULL,
    quantidade_prescrita  NUMBER(4)    NOT NULL,

    CONSTRAINT item_prescricao_pk          PRIMARY KEY (id_prescricao, id_medicamento),
    CONSTRAINT item_prescricao_presc_fk    FOREIGN KEY (id_prescricao) REFERENCES Prescricao (id_prescricao)
                                           ON DELETE CASCADE,
    CONSTRAINT item_prescricao_med_fk      FOREIGN KEY (id_medicamento) REFERENCES Medicamento (id_medicamento),
    CONSTRAINT item_prescricao_diag_fk     FOREIGN KEY (id_diagnostico) REFERENCES Diagnostico (id_diagnostico),
    CONSTRAINT item_prescricao_via_ck      CHECK (via_adm IN ('Oral', 'Tópica', 'Otológica', 'Oftálmica','Subcutânea', 'Intramuscular', 'Intravenosa')),
    CONSTRAINT item_prescricao_qtd_ck      CHECK (quantidade_prescrita > 0)
);