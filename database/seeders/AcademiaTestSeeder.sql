-- Academia Test Schema & Seed Data
-- These tables simulate the real academia DB for integration tests

CREATE TABLE IF NOT EXISTS personas (
    dni VARCHAR(20) PRIMARY KEY,
    nombres VARCHAR(255) NOT NULL,
    apellido_paterno VARCHAR(255) NOT NULL,
    apellido_materno VARCHAR(255) NOT NULL,
    telefono VARCHAR(20)
);

CREATE TABLE IF NOT EXISTS alumnos (
    codigo VARCHAR(50) PRIMARY KEY,
    persona_dni VARCHAR(20) NOT NULL REFERENCES personas(dni),
    email VARCHAR(255)
);

CREATE TABLE IF NOT EXISTS ciclos (
    id SERIAL PRIMARY KEY,
    periodo VARCHAR(100),
    fecha_inicio DATE,
    fecha_fin DATE
);

CREATE TABLE IF NOT EXISTS matriculas (
    id SERIAL PRIMARY KEY,
    ciclo_id INT REFERENCES ciclos(id)
);

CREATE TABLE IF NOT EXISTS aulas (
    id SERIAL PRIMARY KEY,
    matricula_id INT REFERENCES matriculas(id),
    nombre VARCHAR(100)
);

CREATE TABLE IF NOT EXISTS alumno_matricula (
    id SERIAL PRIMARY KEY,
    alumno_codigo VARCHAR(50) NOT NULL REFERENCES alumnos(codigo),
    aula_id INT REFERENCES aulas(id),
    estado SMALLINT NOT NULL DEFAULT 2,
    estado_aula SMALLINT NOT NULL DEFAULT 1,
    fecha TIMESTAMP DEFAULT NOW(),
    matricularegular_id BIGINT
);

-- Clean existing data
DELETE FROM alumno_matricula;
DELETE FROM aulas;
DELETE FROM matriculas;
DELETE FROM ciclos;
DELETE FROM alumnos;
DELETE FROM personas;

-- Active cycle (fecha_fin >= today)
INSERT INTO ciclos (id, periodo, fecha_inicio, fecha_fin)
VALUES (1, '2026-I', '2026-03-01', '2026-12-31');
INSERT INTO ciclos (id, periodo, fecha_inicio, fecha_fin)
VALUES (2, 'VERANO 2026', '2026-01-01', '2026-02-28');
INSERT INTO ciclos (id, periodo, fecha_inicio, fecha_fin)
VALUES (3, 'VERANO 2025', '2025-01-01', '2025-02-28');
INSERT INTO ciclos (id, periodo, fecha_inicio, fecha_fin)
VALUES (4, 'ANUAL 2025', '2025-03-01', '2025-12-31');

INSERT INTO matriculas (id, ciclo_id) VALUES (1, 1);
INSERT INTO matriculas (id, ciclo_id) VALUES (2, 2);
INSERT INTO matriculas (id, ciclo_id) VALUES (3, 3);
INSERT INTO matriculas (id, ciclo_id) VALUES (4, 4);

INSERT INTO aulas (id, matricula_id, nombre) VALUES (1, 1, 'AULA 101');
INSERT INTO aulas (id, matricula_id, nombre) VALUES (2, 2, 'AULA 102');
INSERT INTO aulas (id, matricula_id, nombre) VALUES (3, 3, 'AULA 103');
INSERT INTO aulas (id, matricula_id, nombre) VALUES (4, 4, 'AULA 104');

-- Personas for matching tests
INSERT INTO personas (dni, nombres, apellido_paterno, apellido_materno, telefono) VALUES
('12345678', 'JUAN', 'LOPEZ', 'GARCIA', '999111000'),
('23456789', 'DIEGO', 'CASTILLO', 'TORIBIO', '999111001'),
('34567890', 'JHON', 'RAMOS', 'LOPEZ', '999111002'),
('34567891', 'JOHN', 'RAMOS', 'LOPEZ', '999111003'),
('45678901', 'PEDRO', 'GONZALES', 'DE LA FLOR', '999111004'),
('45678902', 'PEDRO', 'GONZALES', 'DEL FLOR', '999111005'),
('45678903', 'PEDRO', 'GONZALES', 'LAS FLORES', '999111006'),
('45678904', 'PEDRO', 'GONZALES', 'FLORES', '999111007'),
('45678905', 'PEDRO', 'GONZALES', 'FLORINDA', '999111008'),
('56789012', 'MARIA', 'GARCIA', 'LOPEZ', '999111009'),
('56789013', 'MARIA', 'GARCIA', 'LOPERA', '999111010'),
('56789014', 'MARIA', 'GARCIA', 'LOPES', '999111011'),
('56789015', 'MARIA', 'GARCIA', 'LOBATO', '999111012'),
('56789016', 'MARIA', 'GARCIA', 'LONA', '999111013'),
('67890123', 'ANA', 'PEREZ', 'MENDOZA', '999111014'),
('78901234', 'CARLOS', 'MARTINEZ', 'SANCHEZ', '999111015'),
('89012345', 'LUIS', 'GARCIA', 'TORRES', '999111016'),
('90123456', 'XXXXX', 'YYYYY', 'ZZZZZ', '999111017');

INSERT INTO alumnos (codigo, persona_dni, email) VALUES
('A00001', '12345678', 'juan.lopez@test.com'),
('A00002', '23456789', 'diego.castillo@test.com'),
('A00003', '34567890', 'jhon.ramos@test.com'),
('A00004', '34567891', 'john.ramos@test.com'),
('A00005', '45678901', 'pedro.gonzales@test.com'),
('A00006', '45678902', 'pedro.gonzales2@test.com'),
('A00007', '45678903', 'pedro.gonzales3@test.com'),
('A00008', '45678904', 'pedro.gonzales4@test.com'),
('A00009', '45678905', 'pedro.gonzales5@test.com'),
('A00010', '56789012', 'maria.garcia@test.com'),
('A00011', '56789013', 'maria.garcia2@test.com'),
('A00012', '56789014', 'maria.garcia3@test.com'),
('A00013', '56789015', 'maria.garcia4@test.com'),
('A00014', '56789016', 'maria.garcia5@test.com'),
('A00015', '67890123', 'ana.perez@test.com'),
('A00016', '78901234', 'carlos.martinez@test.com'),
('A00017', '89012345', 'luis.garcia@test.com'),
('A00018', '90123456', 'xxxxx@test.com');

-- Active enrolled students (estado IN 2,3,9,13, estado_aula=1, active ciclo)
INSERT INTO alumno_matricula (id, alumno_codigo, aula_id, estado, estado_aula, matricularegular_id) VALUES
(100, 'A00001', 1, 2, 1, NULL),  -- LOPEZ GARCIA, JUAN (MATRICULADO)
(101, 'A00002', 1, 2, 1, NULL),  -- CASTILLO TORIBIO, DIEGO (MATRICULADO)
(102, 'A00003', 1, 2, 1, NULL),  -- RAMOS LOPEZ, JHON (MATRICULADO) - exact match
(103, 'A00004', 1, 2, 1, NULL),  -- RAMOS LOPEZ, JOHN (MATRICULADO) - fuzzy candidate
(104, 'A00005', 1, 2, 1, NULL),  -- GONZALES DE LA FLOR, PEDRO
(105, 'A00006', 1, 2, 1, NULL),  -- GONZALES DEL FLOR, PEDRO - fuzzy candidate
(106, 'A00007', 1, 2, 1, NULL),  -- GONZALES LAS FLORES, PEDRO - fuzzy candidate
(107, 'A00008', 1, 2, 1, NULL),  -- GONZALES FLORES, PEDRO - fuzzy candidate
(108, 'A00009', 1, 2, 1, NULL),  -- GONZALES FLORINDA, PEDRO - fuzzy candidate
(109, 'A00010', 1, 2, 1, NULL),  -- GARCIA LOPEZ, MARIA
(110, 'A00011', 1, 2, 1, NULL),  -- GARCIA LOPERA, MARIA
(111, 'A00012', 1, 2, 1, NULL),  -- GARCIA LOPES, MARIA
(112, 'A00013', 1, 2, 1, NULL),  -- GARCIA LOBATO, MARIA
(113, 'A00014', 1, 2, 1, NULL),  -- GARCIA LONA, MARIA
(114, 'A00015', 1, 2, 1, NULL),  -- PEREZ MENDOZA, ANA (low similarity)
(115, 'A00016', 1, 2, 1, NULL),  -- MARTINEZ SANCHEZ, CARLOS
(116, 'A00017', 1, 2, 1, NULL),  -- GARCIA TORRES, LUIS
(117, 'A00018', 1, 2, 1, NULL);  -- YYYYY ZZZZZ, XXXXX (no match)
