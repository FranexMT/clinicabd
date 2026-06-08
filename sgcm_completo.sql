-- ============================================================
-- SGCM — SISTEMA DE GESTIÓN DE CLÍNICA MÉDICA
-- Base de datos completa (5 nodos)
-- Bases de Datos Distribuidas — UABC 2026
-- ============================================================
-- INSTRUCCIONES:
-- 1. Abrir MySQL Workbench o terminal MySQL
-- 2. Copiar y pegar TODO el archivo
-- 3. Se crearán las 5 bases de datos con sus tablas y datos
-- ============================================================
-- Usuario para acceso remoto (opcional):
-- CREATE USER IF NOT EXISTS 'bdd_user'@'%' IDENTIFIED BY 'Sgcm2026#';
-- GRANT ALL PRIVILEGES ON sgcm_nodo1.* TO 'bdd_user'@'%';
-- GRANT ALL PRIVILEGES ON sgcm_nodo2.* TO 'bdd_user'@'%';
-- GRANT ALL PRIVILEGES ON sgcm_nodo3.* TO 'bdd_user'@'%';
-- GRANT ALL PRIVILEGES ON sgcm_nodo4.* TO 'bdd_user'@'%';
-- GRANT ALL PRIVILEGES ON sgcm_nodo5.* TO 'bdd_user'@'%';
-- FLUSH PRIVILEGES;
-- ============================================================


-- ============================================================
-- SGCM — Nodo 1: Recepción
-- Tablas: ESPECIALIDAD, MEDICO, PACIENTE_V1, CITA_F1
-- CITA_F1 = citas PROGRAMADAS del primer semestre
-- ============================================================

CREATE DATABASE IF NOT EXISTS sgcm_nodo1 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sgcm_nodo1;

-- ------------------------------------------------------------
-- ESPECIALIDAD
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS ESPECIALIDAD (
    id_especialidad INT          PRIMARY KEY AUTO_INCREMENT,
    nombre          VARCHAR(80)  NOT NULL UNIQUE,
    descripcion     VARCHAR(200)
) ENGINE=InnoDB;

INSERT INTO ESPECIALIDAD (nombre, descripcion) VALUES
('Medicina General',     'Atención primaria y consulta general'),
('Pediatría',            'Atención médica a niños y adolescentes'),
('Cardiología',          'Diagnóstico y tratamiento de enfermedades del corazón'),
('Dermatología',         'Enfermedades de la piel, cabello y uñas'),
('Ginecología',          'Salud reproductiva femenina'),
('Neurología',           'Trastornos del sistema nervioso'),
('Ortopedia',            'Lesiones y enfermedades del aparato locomotor'),
('Oftalmología',         'Enfermedades de los ojos'),
('Nutrición',            'Evaluación y orientación nutricional'),
('Psicología Clínica',   'Atención de salud mental');

-- ------------------------------------------------------------
-- MEDICO
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS MEDICO (
    id_medico       INT          PRIMARY KEY AUTO_INCREMENT,
    nombre          VARCHAR(50)  NOT NULL,
    apellido_p      VARCHAR(50)  NOT NULL,
    apellido_m      VARCHAR(50),
    cedula          VARCHAR(20)  NOT NULL UNIQUE,
    telefono        VARCHAR(15),
    email           VARCHAR(100) UNIQUE,
    id_especialidad INT          NOT NULL,
    turno           VARCHAR(10)  DEFAULT 'matutino',
    CONSTRAINT fk_medico_esp FOREIGN KEY (id_especialidad)
        REFERENCES ESPECIALIDAD(id_especialidad)
) ENGINE=InnoDB;

INSERT INTO MEDICO (nombre, apellido_p, apellido_m, cedula, telefono, email, id_especialidad, turno) VALUES
('Carlos',   'Ramírez',   'Torres',    'CED-001', '6641110001', 'c.ramirez@clinica.mx',   1, 'matutino'),
('Laura',    'Mendoza',   'Ríos',      'CED-002', '6641110002', 'l.mendoza@clinica.mx',   2, 'vespertino'),
('Jorge',    'Salinas',   'Vega',      'CED-003', '6641110003', 'j.salinas@clinica.mx',   3, 'matutino'),
('Ana',      'Fuentes',   'Cruz',      'CED-004', '6641110004', 'a.fuentes@clinica.mx',   4, 'vespertino'),
('Roberto',  'Herrera',   'Leal',      'CED-005', '6641110005', 'r.herrera@clinica.mx',   5, 'matutino'),
('Patricia', 'Gómez',     'Nava',      'CED-006', '6641110006', 'p.gomez@clinica.mx',     6, 'nocturno'),
('Miguel',   'Torres',    'Soto',      'CED-007', '6641110007', 'm.torres@clinica.mx',    7, 'matutino'),
('Sofía',    'Castillo',  'Peña',      'CED-008', '6641110008', 's.castillo@clinica.mx',  8, 'vespertino'),
('Diego',    'Morales',   'Ruiz',      'CED-009', '6641110009', 'd.morales@clinica.mx',   9, 'matutino'),
('Elena',    'Vargas',    'Ibarra',    'CED-010', '6641110010', 'e.vargas@clinica.mx',   10, 'vespertino'),
('Luis',     'Jiménez',   'Acosta',    'CED-011', '6641110011', 'l.jimenez@clinica.mx',   1, 'nocturno'),
('María',    'Reyes',     'Campos',    'CED-012', '6641110012', 'm.reyes@clinica.mx',      2, 'matutino');

-- ------------------------------------------------------------
-- PACIENTE_V1 — Fragmento vertical: datos de contacto
-- Atributos: id_paciente, nombre, apellido_p, apellido_m,
--            telefono, email, activo
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PACIENTE_V1 (
    id_paciente INT          PRIMARY KEY,
    nombre      VARCHAR(50)  NOT NULL,
    apellido_p  VARCHAR(50)  NOT NULL,
    apellido_m  VARCHAR(50),
    telefono    VARCHAR(15),
    email       VARCHAR(100) UNIQUE,
    activo      TINYINT(1)   DEFAULT 1
) ENGINE=InnoDB;

INSERT INTO PACIENTE_V1 (id_paciente, nombre, apellido_p, apellido_m, telefono, email, activo) VALUES
( 1, 'Juan',       'García',    'López',    '6642001001', 'juan.garcia@mail.com',    1),
( 2, 'María',      'Hernández', 'Martínez', '6642001002', 'maria.hern@mail.com',     1),
( 3, 'Pedro',      'Gutiérrez', 'Sánchez',  '6642001003', 'pedro.gut@mail.com',      1),
( 4, 'Ana',        'Díaz',      'Romero',   '6642001004', 'ana.diaz@mail.com',       1),
( 5, 'Luis',       'Moreno',    'Jiménez',  '6642001005', 'luis.mor@mail.com',       1),
( 6, 'Carmen',     'Álvarez',   'Torres',   '6642001006', 'carmen.alv@mail.com',     1),
( 7, 'José',       'Ruiz',      'Flores',   '6642001007', 'jose.ruiz@mail.com',      0),
( 8, 'Isabel',     'Fernández', 'Cruz',     '6642001008', 'isabel.fer@mail.com',     1),
( 9, 'Francisco',  'López',     'Vega',     '6642001009', 'fco.lopez@mail.com',      1),
(10, 'Laura',      'Martínez',  'Molina',   '6642001010', 'laura.mtz@mail.com',      1),
(11, 'Antonio',    'González',  'Reyes',    '6642001011', 'antonio.gon@mail.com',    1),
(12, 'Elena',      'Pérez',     'Castillo', '6642001012', 'elena.per@mail.com',      1),
(13, 'Carlos',     'Sánchez',   'Núñez',    '6642001013', 'carlos.san@mail.com',     1),
(14, 'Rosa',       'Ramírez',   'Vargas',   '6642001014', 'rosa.ram@mail.com',       0),
(15, 'Manuel',     'Torres',    'Fuentes',  '6642001015', 'manuel.tor@mail.com',     1);

-- ------------------------------------------------------------
-- CITA_F1 — Fragmento horizontal:
--   estatus = 'programada' AND fecha_cita ENTRE 2026-01-01 Y 2026-06-30
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS CITA_F1 (
    id_cita     INT          PRIMARY KEY AUTO_INCREMENT,
    id_paciente INT          NOT NULL,
    id_medico   INT          NOT NULL,
    fecha_cita  DATE         NOT NULL,
    hora_cita   TIME         NOT NULL,
    motivo      VARCHAR(200),
    estatus     VARCHAR(20)  DEFAULT 'programada',
    CONSTRAINT chk_cita_f1_estatus CHECK (estatus = 'programada'),
    CONSTRAINT chk_cita_f1_fecha   CHECK (fecha_cita BETWEEN '2026-01-01' AND '2026-06-30'),
    CONSTRAINT fk_f1_paciente FOREIGN KEY (id_paciente) REFERENCES PACIENTE_V1(id_paciente),
    CONSTRAINT fk_f1_medico   FOREIGN KEY (id_medico)   REFERENCES MEDICO(id_medico)
) ENGINE=InnoDB;

INSERT INTO CITA_F1 (id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus) VALUES
( 1,  1, '2026-01-10', '09:00:00', 'Chequeo general',            'programada'),
( 2,  2, '2026-01-15', '10:30:00', 'Control pediátrico',         'programada'),
( 3,  3, '2026-02-03', '08:00:00', 'Dolor en el pecho',          'programada'),
( 4,  4, '2026-02-14', '11:00:00', 'Revisión dermatológica',     'programada'),
( 5,  5, '2026-03-01', '09:30:00', 'Consulta ginecológica',      'programada'),
( 6,  6, '2026-03-20', '15:00:00', 'Dolores de cabeza frecuentes','programada'),
( 7,  7, '2026-04-05', '08:30:00', 'Dolor rodilla derecha',      'programada'),
( 8,  8, '2026-04-22', '10:00:00', 'Revisión de la vista',       'programada'),
( 9,  9, '2026-05-10', '09:00:00', 'Plan nutricional',           'programada'),
(10, 10, '2026-05-25', '14:00:00', 'Ansiedad generalizada',      'programada'),
(11,  1, '2026-06-08', '08:00:00', 'Fiebre y malestar general',  'programada'),
(12,  2, '2026-06-15', '10:00:00', 'Vacunas anuales',            'programada'),
(13,  3, '2026-06-20', '09:30:00', 'Seguimiento cardiológico',   'programada'),
(14,  4, '2026-06-25', '11:30:00', 'Acné persistente',           'programada'),
(15,  5, '2026-06-30', '08:00:00', 'Control prenatal',           'programada');

-- ============================================================
-- CONSULTA ÓPTIMA — NODO 1
-- Caso de uso: Listar todas las citas programadas de un
-- paciente específico con nombre del médico y especialidad.
-- ============================================================
-- Alternativa 3 (selección + proyección temprana):
-- Se filtra primero PACIENTE_V1 por id y solo se seleccionan
-- las columnas necesarias antes del JOIN.

SELECT
    c.id_cita,
    c.fecha_cita,
    c.hora_cita,
    c.motivo,
    CONCAT(m.nombre, ' ', m.apellido_p) AS medico,
    e.nombre                            AS especialidad
FROM CITA_F1 c
JOIN MEDICO       m ON c.id_medico   = m.id_medico
JOIN ESPECIALIDAD e ON m.id_especialidad = e.id_especialidad
WHERE c.id_paciente = 1     -- reemplazar con el id del paciente buscado
ORDER BY c.fecha_cita, c.hora_cita;
-- ============================================================
-- SGCM — Nodo 2: Médicos
-- Tablas: PACIENTE_V2, CITA_F2, CONSULTA, EXPEDIENTE,
--         RECETA, DETALLE_RECETA
-- CITA_F2 = citas PROGRAMADAS del segundo semestre
-- ============================================================

CREATE DATABASE IF NOT EXISTS sgcm_nodo2 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sgcm_nodo2;

-- ------------------------------------------------------------
-- PACIENTE_V2 — Fragmento vertical: datos clínicos
-- Atributos: id_paciente, nombre, apellido_p, apellido_m,
--            fecha_nac, sexo, tipo_sangre, fecha_registro
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PACIENTE_V2 (
    id_paciente     INT         PRIMARY KEY,
    nombre          VARCHAR(50) NOT NULL,
    apellido_p      VARCHAR(50) NOT NULL,
    apellido_m      VARCHAR(50),
    fecha_nac       DATE        NOT NULL,
    sexo            CHAR(1)     NOT NULL,
    tipo_sangre     VARCHAR(3),
    fecha_registro  DATE        NOT NULL,
    CONSTRAINT chk_v2_sexo CHECK (sexo IN ('M','F'))
) ENGINE=InnoDB;

INSERT INTO PACIENTE_V2 (id_paciente, nombre, apellido_p, apellido_m, fecha_nac, sexo, tipo_sangre, fecha_registro) VALUES
( 1, 'Juan',      'García',    'López',    '1990-03-15', 'M', 'O+',  '2024-01-10'),
( 2, 'María',     'Hernández', 'Martínez', '1985-07-22', 'F', 'A+',  '2024-01-15'),
( 3, 'Pedro',     'Gutiérrez', 'Sánchez',  '1978-11-05', 'M', 'B+',  '2024-02-01'),
( 4, 'Ana',       'Díaz',      'Romero',   '1995-02-28', 'F', 'AB+', '2024-02-10'),
( 5, 'Luis',      'Moreno',    'Jiménez',  '2001-06-18', 'M', 'O-',  '2024-03-05'),
( 6, 'Carmen',    'Álvarez',   'Torres',   '1970-09-30', 'F', 'A-',  '2024-03-12'),
( 7, 'José',      'Ruiz',      'Flores',   '1988-12-01', 'M', 'B-',  '2024-04-01'),
( 8, 'Isabel',    'Fernández', 'Cruz',     '1993-04-17', 'F', 'O+',  '2024-04-20'),
( 9, 'Francisco', 'López',     'Vega',     '1965-08-25', 'M', 'A+',  '2024-05-08'),
(10, 'Laura',     'Martínez',  'Molina',   '1999-01-09', 'F', 'AB-', '2024-05-20'),
(11, 'Antonio',   'González',  'Reyes',    '1982-05-14', 'M', 'O+',  '2024-06-03'),
(12, 'Elena',     'Pérez',     'Castillo', '1975-10-21', 'F', 'A+',  '2024-06-15'),
(13, 'Carlos',    'Sánchez',   'Núñez',    '1991-03-07', 'M', 'B+',  '2024-07-01'),
(14, 'Rosa',      'Ramírez',   'Vargas',   '2003-11-30', 'F', 'O-',  '2024-07-10'),
(15, 'Manuel',    'Torres',    'Fuentes',  '1960-06-06', 'M', 'A-',  '2024-08-01');

-- ------------------------------------------------------------
-- CITA_F2 — Fragmento horizontal:
--   estatus = 'programada' AND fecha_cita ENTRE 2026-07-01 Y 2026-12-31
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS CITA_F2 (
    id_cita     INT          PRIMARY KEY AUTO_INCREMENT,
    id_paciente INT          NOT NULL,
    id_medico   INT          NOT NULL,
    fecha_cita  DATE         NOT NULL,
    hora_cita   TIME         NOT NULL,
    motivo      VARCHAR(200),
    estatus     VARCHAR(20)  DEFAULT 'programada',
    CONSTRAINT chk_cita_f2_estatus CHECK (estatus = 'programada'),
    CONSTRAINT chk_cita_f2_fecha   CHECK (fecha_cita BETWEEN '2026-07-01' AND '2026-12-31'),
    CONSTRAINT fk_f2_paciente FOREIGN KEY (id_paciente) REFERENCES PACIENTE_V2(id_paciente)
) ENGINE=InnoDB;

INSERT INTO CITA_F2 (id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus) VALUES
( 1,  1, '2026-07-05', '09:00:00', 'Control semestral',           'programada'),
( 2,  2, '2026-07-18', '10:00:00', 'Seguimiento pediátrico',      'programada'),
( 3,  3, '2026-08-02', '08:30:00', 'Ecocardiograma de control',   'programada'),
( 4,  4, '2026-08-20', '11:00:00', 'Tratamiento dermatológico',   'programada'),
( 5,  5, '2026-09-10', '09:30:00', 'Control ginecológico',        'programada'),
( 6,  6, '2026-09-25', '15:00:00', 'Resonancia magnética',        'programada'),
( 7,  7, '2026-10-07', '08:00:00', 'Rehabilitación rodilla',      'programada'),
( 8,  8, '2026-10-19', '10:30:00', 'Graduación lentes',           'programada'),
( 9,  9, '2026-11-03', '09:00:00', 'Evaluación nutricional',      'programada'),
(10, 10, '2026-11-17', '14:00:00', 'Terapia psicológica',         'programada'),
(11,  1, '2026-12-01', '08:00:00', 'Revisión anual',              'programada'),
(12,  2, '2026-12-10', '10:00:00', 'Refuerzo vacunal',            'programada');

-- ------------------------------------------------------------
-- EXPEDIENTE
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS EXPEDIENTE (
    id_expediente   INT          PRIMARY KEY AUTO_INCREMENT,
    id_paciente     INT          NOT NULL UNIQUE,
    alergias        VARCHAR(300),
    antecedentes    VARCHAR(500),
    fecha_apertura  DATE         NOT NULL,
    CONSTRAINT fk_exp_paciente FOREIGN KEY (id_paciente)
        REFERENCES PACIENTE_V2(id_paciente)
) ENGINE=InnoDB;

INSERT INTO EXPEDIENTE (id_paciente, alergias, antecedentes, fecha_apertura) VALUES
( 1, 'Penicilina',                      'Hipertensión arterial. Padre diabético.',         '2024-01-10'),
( 2, 'Ninguna conocida',                'Asma leve controlada.',                           '2024-01-15'),
( 3, 'Ibuprofeno',                      'Cardiopatía isquémica. Fumador ex.',              '2024-02-01'),
( 4, 'Polen, ácaros',                   'Rinitis alérgica crónica.',                       '2024-02-10'),
( 5, 'Ninguna conocida',                'Sin antecedentes relevantes.',                    '2024-03-05'),
( 6, 'Sulfonamidas',                    'Diabetes tipo 2. Hipotiroidismo.',                '2024-03-12'),
( 7, 'Latex',                           'Fractura de clavícula (2020).',                   '2024-04-01'),
( 8, 'Ninguna conocida',                'Migraña crónica.',                                '2024-04-20'),
( 9, 'Aspirina, NSAIDs',                'HTA. Dislipidemia. Paciente crónico.',            '2024-05-08'),
(10, 'Ninguna conocida',                'Ansiedad generalizada. Tratamiento psicológico.', '2024-05-20'),
(11, 'Amoxicilina',                     'Apendicectomía (2015).',                          '2024-06-03'),
(12, 'Ninguna conocida',                'Osteoporosis leve.',                              '2024-06-15'),
(13, 'Dipirona',                        'Sin antecedentes relevantes.',                    '2024-07-01'),
(14, 'Ninguna conocida',                'Asma alérgica.',                                  '2024-07-10'),
(15, 'Contraste yodado',                'Insuficiencia renal crónica leve.',               '2024-08-01');

-- ------------------------------------------------------------
-- CONSULTA  (referencias a CITA de cualquier nodo — FK lógica)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS CONSULTA (
    id_consulta     INT          PRIMARY KEY AUTO_INCREMENT,
    id_cita         INT          NOT NULL UNIQUE,
    diagnostico     VARCHAR(500) NOT NULL,
    observaciones   VARCHAR(500),
    fecha_consulta  DATE         NOT NULL
) ENGINE=InnoDB;

-- Las consultas corresponden a citas completadas (viven en Nodo 3 y 4),
-- pero el registro clínico se gestiona en el Nodo 2.
INSERT INTO CONSULTA (id_cita, diagnostico, observaciones, fecha_consulta) VALUES
(101, 'Hipertensión arterial grado 1',           'Iniciar tratamiento con losartán 50 mg.',       '2025-03-10'),
(102, 'Faringoamigdalitis bacteriana',            'Amoxicilina 500 mg por 7 días.',               '2025-03-15'),
(103, 'Infarto agudo de miocardio (IAM)',         'Traslado a urgencias. Aspirina 300 mg cargado.','2025-04-05'),
(104, 'Dermatitis atópica moderada',              'Hidrocortisona tópica al 1%.',                  '2025-04-20'),
(105, 'Embarazo 10 semanas — control normal',     'Ácido fólico 5 mg. Próxima cita: 4 semanas.',   '2025-05-12'),
(106, 'Cefalea tensional crónica',                'Naproxeno 550 mg. Técnicas de relajación.',     '2025-05-28'),
(107, 'Gonalgia bilateral por desgaste',          'Fisioterapia. Ibuprofeno 600 mg si dolor.',     '2025-06-10'),
(108, 'Miopía -2.75 OD / -3.00 OI',              'Prescripción de lentes corregidos.',            '2025-06-25'),
(109, 'Sobrepeso grado I (IMC 27.8)',             'Plan dietético hipocalórico + actividad física.','2025-07-08'),
(110, 'Trastorno de ansiedad generalizada',       'Terapia cognitivo-conductual 1 vez/semana.',    '2025-07-22'),
(111, 'Infección de vías urinarias (IVU)',        'Ciprofloxacino 500 mg 2 veces al día 7 días.',  '2025-08-05'),
(112, 'Gastroenteritis viral',                    'Hidratación oral. Dieta blanda.',               '2025-08-18'),
(113, 'Lumbalgia mecánica aguda',                 'Reposo relativo 3 días. Diclofenaco 75 mg.',    '2025-09-01'),
(114, 'Asma bronquial alérgica',                  'Salbutamol inhalador. Montelukast 10 mg.',      '2025-09-15'),
(115, 'Enfermedad renal crónica estadio 2',       'Restricción proteínica. Nefrólogo.',            '2025-10-02');

-- ------------------------------------------------------------
-- RECETA
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS RECETA (
    id_receta     INT          PRIMARY KEY AUTO_INCREMENT,
    id_consulta   INT          NOT NULL,
    fecha_emision DATE         NOT NULL,
    indicaciones  VARCHAR(300),
    CONSTRAINT fk_receta_consulta FOREIGN KEY (id_consulta)
        REFERENCES CONSULTA(id_consulta)
) ENGINE=InnoDB;

INSERT INTO RECETA (id_consulta, fecha_emision, indicaciones) VALUES
(101, '2025-03-10', 'Tomar con alimentos. Control en 1 mes.'),
(102, '2025-03-15', 'Completar el antibiótico aunque mejore.'),
(103, '2025-04-05', 'Medicación de urgencia. No suspender.'),
(104, '2025-04-20', 'Aplicar 2 veces al día en área afectada.'),
(105, '2025-05-12', 'Tomar en ayunas por la mañana.'),
(106, '2025-05-28', 'Solo si el dolor supera 6/10.'),
(107, '2025-06-10', 'No exceder 1200 mg/día de ibuprofeno.'),
(108, '2025-06-25', 'Revisión de la graduación en 6 meses.'),
(109, '2025-07-08', 'Vitamina D3 1000 UI diaria.'),
(110, '2025-07-22', 'Continuar terapia. Evitar cafeína.'),
(111, '2025-08-05', 'Tomar cada 12 horas durante 7 días.'),
(112, '2025-08-18', 'Suero oral cada 2 horas. Reposo.'),
(113, '2025-09-01', 'Aplicar calor local 15 min 2 veces al día.'),
(114, '2025-09-15', 'Inhalar salbutamol solo en crisis.'),
(115, '2025-10-02', 'Limitar proteína animal. Próximo control laboratorio.');

-- ------------------------------------------------------------
-- DETALLE_RECETA
-- (id_medicamento referencia lógica a Nodo 3 — MEDICAMENTO)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DETALLE_RECETA (
    id_detalle      INT  PRIMARY KEY AUTO_INCREMENT,
    id_receta       INT  NOT NULL,
    id_medicamento  INT  NOT NULL,
    cantidad        INT  NOT NULL,
    duracion_dias   INT,
    CONSTRAINT fk_det_receta FOREIGN KEY (id_receta)
        REFERENCES RECETA(id_receta)
) ENGINE=InnoDB;

INSERT INTO DETALLE_RECETA (id_receta, id_medicamento, cantidad, duracion_dias) VALUES
( 1,  1, 30, 30),
( 2,  2, 21,  7),
( 3,  3,  1,  1),
( 4,  4,  1, 14),
( 5,  5, 30, 30),
( 6,  6, 10, 10),
( 7,  7, 20, 10),
( 8,  8,  1,  0),
( 9,  9, 30, 30),
(10, 10, 30, 30),
(11,  2, 14,  7),
(12, 11,  5,  5),
(13,  6, 10,  5),
(14, 12,  1,  0),
(15, 13, 30, 30);

-- ============================================================
-- CONSULTA ÓPTIMA — NODO 2
-- Caso de uso: Expediente clínico completo de un paciente:
-- datos personales, diagnósticos y recetas activas.
-- Alternativa 3: selección + proyección temprana
-- ============================================================
SELECT
    p.id_paciente,
    CONCAT(p.nombre, ' ', p.apellido_p) AS paciente,
    p.fecha_nac,
    p.tipo_sangre,
    exp.alergias,
    exp.antecedentes,
    con.id_consulta,
    con.fecha_consulta,
    con.diagnostico,
    rec.id_receta,
    rec.indicaciones
FROM (
    SELECT id_paciente, nombre, apellido_p, fecha_nac, tipo_sangre
    FROM PACIENTE_V2
    WHERE id_paciente = 1               -- reemplazar con el id buscado
) p
JOIN EXPEDIENTE  exp ON exp.id_paciente  = p.id_paciente
JOIN CONSULTA    con ON con.id_consulta IS NOT NULL   -- todos los registros de este paciente
JOIN RECETA      rec ON rec.id_consulta  = con.id_consulta
ORDER BY con.fecha_consulta DESC;
-- ============================================================
-- SGCM — Nodo 3: Farmacia
-- Tablas: MEDICAMENTO, DETALLE_RECETA (réplica), CITA_F3
-- CITA_F3 = citas COMPLETADAS del primer semestre
-- ============================================================

CREATE DATABASE IF NOT EXISTS sgcm_nodo3 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sgcm_nodo3;

-- ------------------------------------------------------------
-- MEDICAMENTO
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS MEDICAMENTO (
    id_medicamento INT            PRIMARY KEY AUTO_INCREMENT,
    nombre         VARCHAR(100)   NOT NULL,
    presentacion   VARCHAR(80),
    dosis_std      VARCHAR(50),
    stock          INT            DEFAULT 0,
    precio         DECIMAL(8,2)
) ENGINE=InnoDB;

INSERT INTO MEDICAMENTO (nombre, presentacion, dosis_std, stock, precio) VALUES
('Losartán',              'Tabletas 50 mg',           '50 mg c/24h',   120, 85.00),
('Amoxicilina',           'Cápsulas 500 mg',          '500 mg c/8h',   200, 45.00),
('Aspirina',              'Tabletas 300 mg',          '300 mg c/24h',  150, 20.00),
('Hidrocortisona crema',  'Crema 1% tubo 20 g',       'Aplicar c/12h',  80, 65.00),
('Ácido fólico',          'Tabletas 5 mg',            '5 mg c/24h',    180, 18.00),
('Naproxeno',             'Tabletas 550 mg',          '550 mg c/12h',  100, 35.00),
('Ibuprofeno',            'Tabletas 600 mg',          '600 mg c/8h',   160, 25.00),
('Vitamina D3',           'Cápsulas 1000 UI',         '1000 UI c/24h', 200, 30.00),
('Melatonina',            'Tabletas 3 mg',            '3 mg al dormir', 90, 55.00),
('Loratadina',            'Tabletas 10 mg',           '10 mg c/24h',   140, 22.00),
('Ciprofloxacino',        'Tabletas 500 mg',          '500 mg c/12h',  100, 60.00),
('Salbutamol inhalador',  'Inhalador 100 mcg/dosis',  '1 puff en crisis', 50, 120.00),
('Montelukast',           'Tabletas 10 mg',           '10 mg c/24h',    75, 95.00),
('Paracetamol',           'Tabletas 500 mg',          '500 mg c/6h',   250, 15.00),
('Omeprazol',             'Cápsulas 20 mg',           '20 mg c/24h',   130, 40.00),
('Metformina',            'Tabletas 850 mg',          '850 mg c/12h',  110, 50.00),
('Levotiroxina',          'Tabletas 50 mcg',          '50 mcg c/24h',   60, 70.00),
('Diclofenaco',           'Tabletas 75 mg',           '75 mg c/12h',   120, 28.00),
('Fluoxetina',            'Cápsulas 20 mg',           '20 mg c/24h',    80, 75.00),
('Atorvastatina',         'Tabletas 20 mg',           '20 mg al dormir',90, 68.00);

-- ------------------------------------------------------------
-- CITA_F3 — Fragmento horizontal:
--   estatus = 'completada' AND fecha_cita ENTRE 2025-01-01 Y 2025-06-30
-- Farmacia usa estas citas para verificar recetas dispensadas.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS CITA_F3 (
    id_cita     INT          PRIMARY KEY,
    id_paciente INT          NOT NULL,
    id_medico   INT          NOT NULL,
    fecha_cita  DATE         NOT NULL,
    hora_cita   TIME         NOT NULL,
    motivo      VARCHAR(200),
    estatus     VARCHAR(20)  DEFAULT 'completada',
    CONSTRAINT chk_cita_f3_estatus CHECK (estatus = 'completada'),
    CONSTRAINT chk_cita_f3_fecha   CHECK (fecha_cita BETWEEN '2025-01-01' AND '2025-06-30')
) ENGINE=InnoDB;

INSERT INTO CITA_F3 (id_cita, id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus) VALUES
(101,  1,  1, '2025-03-10', '09:00:00', 'Chequeo general',             'completada'),
(102,  2,  2, '2025-03-15', '10:30:00', 'Control pediátrico',          'completada'),
(103,  3,  3, '2025-04-05', '08:00:00', 'Dolor en el pecho',           'completada'),
(104,  4,  4, '2025-04-20', '11:00:00', 'Revisión dermatológica',      'completada'),
(105,  5,  5, '2025-05-12', '09:30:00', 'Consulta ginecológica',       'completada'),
(106,  6,  6, '2025-05-28', '15:00:00', 'Dolores de cabeza frecuentes','completada'),
(107,  7,  7, '2025-06-10', '08:30:00', 'Dolor rodilla derecha',       'completada'),
(108,  8,  8, '2025-06-25', '10:00:00', 'Revisión de la vista',        'completada'),
(109,  9,  9, '2025-06-08', '09:00:00', 'Plan nutricional',            'completada'),
(110, 10, 10, '2025-06-20', '14:00:00', 'Ansiedad generalizada',       'completada'),
(111, 11,  1, '2025-01-15', '08:00:00', 'Infección urinaria',          'completada'),
(112, 12,  2, '2025-02-03', '10:00:00', 'Gastroenteritis',             'completada'),
(113, 13,  7, '2025-02-25', '09:30:00', 'Dolor lumbar',                'completada'),
(114, 14,  6, '2025-03-18', '11:30:00', 'Crisis asmática leve',        'completada'),
(115, 15,  1, '2025-04-30', '08:00:00', 'Control renal',               'completada');

-- ------------------------------------------------------------
-- DETALLE_RECETA (réplica)
-- Farmacia necesita saber qué medicamentos tiene que dispensar.
-- Se replica desde Nodo 2 la información de detalle de receta.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS DETALLE_RECETA (
    id_detalle     INT  PRIMARY KEY AUTO_INCREMENT,
    id_receta      INT  NOT NULL,
    id_medicamento INT  NOT NULL,
    cantidad       INT  NOT NULL,
    duracion_dias  INT,
    dispensado     TINYINT(1) DEFAULT 0,   -- campo adicional de farmacia
    CONSTRAINT fk_det_med FOREIGN KEY (id_medicamento)
        REFERENCES MEDICAMENTO(id_medicamento)
) ENGINE=InnoDB;

INSERT INTO DETALLE_RECETA (id_receta, id_medicamento, cantidad, duracion_dias, dispensado) VALUES
( 1,  1, 30, 30, 1),
( 2,  2, 21,  7, 1),
( 3,  3,  1,  1, 1),
( 4,  4,  1, 14, 1),
( 5,  5, 30, 30, 1),
( 6,  6, 10, 10, 1),
( 7,  7, 20, 10, 0),
( 8,  8,  1,  0, 0),
( 9,  9, 30, 30, 1),
(10, 10, 30, 30, 0),
(11,  2, 14,  7, 1),
(12, 11,  5,  5, 1),
(13,  6, 10,  5, 1),
(14, 12,  1,  0, 0),
(15, 13, 30, 30, 0);

-- ============================================================
-- CONSULTA ÓPTIMA — NODO 3
-- Caso de uso: Consultar todas las recetas con medicamentos
-- pendientes de dispensar para citas completadas.
-- Alternativa 3: selección + proyección temprana
-- ============================================================
SELECT
    dr.id_receta,
    m.nombre              AS medicamento,
    m.presentacion,
    dr.cantidad,
    dr.duracion_dias,
    c.id_cita,
    c.id_paciente,
    c.fecha_cita
FROM (
    -- proyección temprana: solo columnas necesarias de DETALLE_RECETA
    SELECT id_detalle, id_receta, id_medicamento, cantidad, duracion_dias
    FROM DETALLE_RECETA
    WHERE dispensado = 0
) dr
JOIN MEDICAMENTO m  ON m.id_medicamento = dr.id_medicamento
JOIN CITA_F3     c  ON c.id_cita = (
    -- correlación: buscar la cita asociada a la receta
    -- en la práctica la receta lleva id_consulta → id_cita
    SELECT id_cita FROM CITA_F3 LIMIT 1  -- simplificado para el nodo local
)
ORDER BY c.fecha_cita, dr.id_receta;

-- Versión simplificada sin correlación (más práctica para el nodo):
SELECT
    dr.id_receta,
    m.nombre        AS medicamento,
    m.presentacion,
    m.precio,
    dr.cantidad,
    dr.cantidad * m.precio AS costo_total
FROM DETALLE_RECETA dr
JOIN MEDICAMENTO    m  ON m.id_medicamento = dr.id_medicamento
WHERE dr.dispensado = 0
ORDER BY dr.id_receta;
-- ============================================================
-- SGCM — Nodo 4: Administración
-- Tablas: FACTURA, PAGO, CITA_F4
-- CITA_F4 = citas COMPLETADAS del segundo semestre
-- ============================================================

CREATE DATABASE IF NOT EXISTS sgcm_nodo4 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sgcm_nodo4;

-- ------------------------------------------------------------
-- CITA_F4 — Fragmento horizontal:
--   estatus = 'completada' AND fecha_cita ENTRE 2025-07-01 Y 2025-12-31
-- Administración la usa para cerrar ciclos de facturación.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS CITA_F4 (
    id_cita     INT          PRIMARY KEY,
    id_paciente INT          NOT NULL,
    id_medico   INT          NOT NULL,
    fecha_cita  DATE         NOT NULL,
    hora_cita   TIME         NOT NULL,
    motivo      VARCHAR(200),
    estatus     VARCHAR(20)  DEFAULT 'completada',
    CONSTRAINT chk_cita_f4_estatus CHECK (estatus = 'completada'),
    CONSTRAINT chk_cita_f4_fecha   CHECK (fecha_cita BETWEEN '2025-07-01' AND '2025-12-31')
) ENGINE=InnoDB;

INSERT INTO CITA_F4 (id_cita, id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus) VALUES
(201,  1,  1, '2025-07-08', '09:00:00', 'Control general semestral',    'completada'),
(202,  2,  2, '2025-07-22', '10:30:00', 'Seguimiento pediátrico',       'completada'),
(203,  3,  3, '2025-08-05', '08:00:00', 'Ecocardiograma',               'completada'),
(204,  4,  4, '2025-08-18', '11:00:00', 'Revisión dermatológica',       'completada'),
(205,  5,  5, '2025-09-02', '09:30:00', 'Control obstétrico',           'completada'),
(206,  6,  6, '2025-09-15', '15:00:00', 'Neurología de seguimiento',    'completada'),
(207,  7,  7, '2025-10-01', '08:30:00', 'Ortopedia control',            'completada'),
(208,  8,  8, '2025-10-20', '10:00:00', 'Oftalmología revisión',        'completada'),
(209,  9,  9, '2025-11-05', '09:00:00', 'Nutrición semestral',          'completada'),
(210, 10, 10, '2025-11-19', '14:00:00', 'Psicología sesión 5',          'completada'),
(211, 11,  1, '2025-12-02', '08:00:00', 'Consulta general',             'completada'),
(212, 12,  2, '2025-12-10', '10:00:00', 'Pediatría anual',              'completada'),
(213, 13,  7, '2025-07-25', '09:00:00', 'Ortopedia dolor lumbar',       'completada'),
(214, 14,  6, '2025-08-30', '11:30:00', 'Neurología cefaleas',          'completada'),
(215, 15,  1, '2025-09-20', '08:00:00', 'Medicina general renal',       'completada');

-- ------------------------------------------------------------
-- FACTURA
-- (id_consulta referencia lógica a CONSULTA en Nodo 2)
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS FACTURA (
    id_factura    INT           PRIMARY KEY AUTO_INCREMENT,
    id_consulta   INT           NOT NULL,
    fecha_emision DATE          NOT NULL,
    subtotal      DECIMAL(10,2) NOT NULL,
    iva           DECIMAL(10,2) NOT NULL,
    total         DECIMAL(10,2) NOT NULL,
    estatus_pago  VARCHAR(20)   DEFAULT 'pendiente',
    CONSTRAINT chk_factura_estatus CHECK (estatus_pago IN ('pendiente','pagado','cancelado'))
) ENGINE=InnoDB;

INSERT INTO FACTURA (id_consulta, fecha_emision, subtotal, iva, total, estatus_pago) VALUES
(201, '2025-07-08',  600.00,  96.00,  696.00, 'pagado'),
(202, '2025-07-22',  500.00,  80.00,  580.00, 'pagado'),
(203, '2025-08-05',  900.00, 144.00, 1044.00, 'pagado'),
(204, '2025-08-18',  700.00, 112.00,  812.00, 'pendiente'),
(205, '2025-09-02',  650.00, 104.00,  754.00, 'pagado'),
(206, '2025-09-15',  800.00, 128.00,  928.00, 'pendiente'),
(207, '2025-10-01',  750.00, 120.00,  870.00, 'pagado'),
(208, '2025-10-20',  550.00,  88.00,  638.00, 'pagado'),
(209, '2025-11-05',  450.00,  72.00,  522.00, 'pendiente'),
(210, '2025-11-19',  600.00,  96.00,  696.00, 'pagado'),
(211, '2025-12-02',  500.00,  80.00,  580.00, 'pendiente'),
(212, '2025-12-10',  520.00,  83.20,  603.20, 'pendiente'),
(213, '2025-07-25',  680.00, 108.80,  788.80, 'pagado'),
(214, '2025-08-30',  720.00, 115.20,  835.20, 'cancelado'),
(215, '2025-09-20',  500.00,  80.00,  580.00, 'pagado');

-- ------------------------------------------------------------
-- PAGO
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PAGO (
    id_pago     INT           PRIMARY KEY AUTO_INCREMENT,
    id_factura  INT           NOT NULL,
    fecha_pago  DATE          NOT NULL,
    monto       DECIMAL(10,2) NOT NULL,
    metodo_pago VARCHAR(30),
    CONSTRAINT chk_pago_metodo CHECK (metodo_pago IN ('efectivo','tarjeta','transferencia')),
    CONSTRAINT fk_pago_factura FOREIGN KEY (id_factura)
        REFERENCES FACTURA(id_factura)
) ENGINE=InnoDB;

INSERT INTO PAGO (id_factura, fecha_pago, monto, metodo_pago) VALUES
( 1, '2025-07-08',  696.00, 'tarjeta'),
( 2, '2025-07-22',  580.00, 'efectivo'),
( 3, '2025-08-05', 1044.00, 'transferencia'),
( 5, '2025-09-02',  754.00, 'tarjeta'),
( 7, '2025-10-01',  870.00, 'efectivo'),
( 8, '2025-10-20',  638.00, 'tarjeta'),
(10, '2025-11-19',  696.00, 'transferencia'),
(13, '2025-07-25',  788.80, 'tarjeta'),
(15, '2025-09-20',  580.00, 'efectivo');

-- ============================================================
-- CONSULTA ÓPTIMA — NODO 4
-- Caso de uso: Estado de cuenta de facturas pendientes de pago
-- con datos del paciente (id_paciente viene de CITA_F4).
-- Alternativa 3: selección + proyección temprana
-- ============================================================
SELECT
    f.id_factura,
    f.fecha_emision,
    c.id_paciente,
    f.subtotal,
    f.iva,
    f.total,
    f.estatus_pago,
    DATEDIFF(CURDATE(), f.fecha_emision) AS dias_vencida
FROM (
    -- selección temprana: solo facturas pendientes
    SELECT id_factura, id_consulta, fecha_emision, subtotal, iva, total, estatus_pago
    FROM FACTURA
    WHERE estatus_pago = 'pendiente'
) f
JOIN CITA_F4 c ON c.id_cita = f.id_consulta
ORDER BY dias_vencida DESC, f.total DESC;
-- ============================================================
-- SGCM — Nodo 5: Reportes
-- Tablas: PACIENTE_V3, CITA_F5
-- CITA_F5 = citas CANCELADAS (cualquier fecha)
-- + Vistas que apuntan a los demás nodos (simuladas localmente)
-- ============================================================

CREATE DATABASE IF NOT EXISTS sgcm_nodo5 CHARACTER SET utf8mb4 COLLATE utf8mb4_unicode_ci;
USE sgcm_nodo5;

-- ------------------------------------------------------------
-- PACIENTE_V3 — Fragmento vertical: atributos estadísticos
-- Atributos: id_paciente, sexo, tipo_sangre, fecha_registro, activo
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS PACIENTE_V3 (
    id_paciente     INT        PRIMARY KEY,
    sexo            CHAR(1)    NOT NULL,
    tipo_sangre     VARCHAR(3),
    fecha_registro  DATE       NOT NULL,
    activo          TINYINT(1) DEFAULT 1,
    CONSTRAINT chk_v3_sexo CHECK (sexo IN ('M','F'))
) ENGINE=InnoDB;

INSERT INTO PACIENTE_V3 (id_paciente, sexo, tipo_sangre, fecha_registro, activo) VALUES
( 1, 'M', 'O+',  '2024-01-10', 1),
( 2, 'F', 'A+',  '2024-01-15', 1),
( 3, 'M', 'B+',  '2024-02-01', 1),
( 4, 'F', 'AB+', '2024-02-10', 1),
( 5, 'M', 'O-',  '2024-03-05', 1),
( 6, 'F', 'A-',  '2024-03-12', 1),
( 7, 'M', 'B-',  '2024-04-01', 0),
( 8, 'F', 'O+',  '2024-04-20', 1),
( 9, 'M', 'A+',  '2024-05-08', 1),
(10, 'F', 'AB-', '2024-05-20', 1),
(11, 'M', 'O+',  '2024-06-03', 1),
(12, 'F', 'A+',  '2024-06-15', 1),
(13, 'M', 'B+',  '2024-07-01', 1),
(14, 'F', 'O-',  '2024-07-10', 0),
(15, 'M', 'A-',  '2024-08-01', 1);

-- ------------------------------------------------------------
-- CITA_F5 — Fragmento horizontal:
--   estatus = 'cancelada' (cualquier fecha)
-- Reportes analiza ausentismo y patrones de cancelación.
-- ------------------------------------------------------------
CREATE TABLE IF NOT EXISTS CITA_F5 (
    id_cita     INT          PRIMARY KEY AUTO_INCREMENT,
    id_paciente INT          NOT NULL,
    id_medico   INT          NOT NULL,
    fecha_cita  DATE         NOT NULL,
    hora_cita   TIME         NOT NULL,
    motivo      VARCHAR(200),
    estatus     VARCHAR(20)  DEFAULT 'cancelada',
    CONSTRAINT chk_cita_f5_estatus CHECK (estatus = 'cancelada')
) ENGINE=InnoDB;

INSERT INTO CITA_F5 (id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus) VALUES
( 3,  3, '2025-02-20', '09:00:00', 'Cardiología — canceló por viaje',      'cancelada'),
( 7,  7, '2025-03-12', '10:30:00', 'Ortopedia — no se presentó',           'cancelada'),
( 2,  2, '2025-04-08', '08:00:00', 'Pediatría — canceló por enfermedad',   'cancelada'),
(10, 10, '2025-04-25', '11:00:00', 'Psicología — reprogramó',              'cancelada'),
( 5,  5, '2025-05-03', '09:30:00', 'Ginecología — canceló sin aviso',      'cancelada'),
(13,  1, '2025-05-18', '15:00:00', 'Med. general — canceló por trabajo',   'cancelada'),
( 1,  6, '2025-06-01', '08:30:00', 'Neurología — canceló por viaje',       'cancelada'),
(14,  4, '2025-07-07', '10:00:00', 'Dermatología — no se presentó',        'cancelada'),
( 8,  8, '2025-07-22', '09:00:00', 'Oftalmología — reprogramó',            'cancelada'),
( 4,  9, '2025-08-10', '14:00:00', 'Nutrición — canceló por trabajo',      'cancelada'),
(11,  3, '2025-09-05', '08:00:00', 'Cardiología — canceló sin aviso',      'cancelada'),
(15,  5, '2025-09-20', '10:00:00', 'Ginecología — canceló por salud',      'cancelada'),
( 6,  7, '2025-10-15', '11:00:00', 'Ortopedia — reprogramó',               'cancelada'),
( 9,  2, '2025-11-03', '09:30:00', 'Pediatría — no se presentó',           'cancelada'),
(12,  1, '2025-12-01', '08:00:00', 'Med. general — canceló por fiestas',   'cancelada');

-- ------------------------------------------------------------
-- VISTAS de resumen (simulan acceso a datos de otros nodos)
-- En producción apuntarían a los nodos remotos vía FEDERATED
-- o mediante dblink. Aquí se incluyen como vistas locales
-- de referencia para el reporte combinado.
-- ------------------------------------------------------------

-- Vista: resumen de cancelaciones por mes
CREATE OR REPLACE VIEW v_cancelaciones_mes AS
SELECT
    YEAR(fecha_cita)  AS anio,
    MONTH(fecha_cita) AS mes,
    COUNT(*)          AS total_cancelaciones
FROM CITA_F5
GROUP BY YEAR(fecha_cita), MONTH(fecha_cita)
ORDER BY anio, mes;

-- Vista: distribución de tipo de sangre de pacientes activos
CREATE OR REPLACE VIEW v_demografia_sangre AS
SELECT
    tipo_sangre,
    COUNT(*) AS total,
    ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM PACIENTE_V3 WHERE activo = 1), 1) AS porcentaje
FROM PACIENTE_V3
WHERE activo = 1
GROUP BY tipo_sangre
ORDER BY total DESC;

-- Vista: distribución por sexo de pacientes activos
CREATE OR REPLACE VIEW v_demografia_sexo AS
SELECT
    CASE sexo WHEN 'M' THEN 'Masculino' ELSE 'Femenino' END AS genero,
    COUNT(*) AS total
FROM PACIENTE_V3
WHERE activo = 1
GROUP BY sexo;

-- Vista: registros de pacientes por mes (crecimiento histórico)
CREATE OR REPLACE VIEW v_crecimiento_pacientes AS
SELECT
    YEAR(fecha_registro)  AS anio,
    MONTH(fecha_registro) AS mes,
    COUNT(*)              AS nuevos_pacientes
FROM PACIENTE_V3
GROUP BY YEAR(fecha_registro), MONTH(fecha_registro)
ORDER BY anio, mes;

-- ============================================================
-- CONSULTA ÓPTIMA — NODO 5
-- Caso de uso: Reporte mensual de citas por estatus, médico
-- y especialidad para análisis estadístico.
-- (Utiliza datos locales de CITA_F5 + vistas de resumen)
-- Alternativa 3: selección + proyección temprana
-- ============================================================

-- Reporte 1: Cancelaciones por mes con tasa acumulada
SELECT
    anio,
    mes,
    total_cancelaciones,
    SUM(total_cancelaciones) OVER (ORDER BY anio, mes) AS cancelaciones_acumuladas
FROM v_cancelaciones_mes;

-- Reporte 2: Perfil demográfico de pacientes activos
SELECT
    sexo.genero,
    sangre.tipo_sangre,
    COUNT(p.id_paciente) AS cantidad
FROM PACIENTE_V3 p
JOIN v_demografia_sexo  sexo   ON (p.sexo = 'M' AND sexo.genero = 'Masculino')
                               OR (p.sexo = 'F' AND sexo.genero = 'Femenino')
LEFT JOIN v_demografia_sangre sangre ON p.tipo_sangre = sangre.tipo_sangre
WHERE p.activo = 1
GROUP BY sexo.genero, sangre.tipo_sangre
ORDER BY sexo.genero, cantidad DESC;

-- Reporte 3: Análisis de ausentismo — top pacientes con más cancelaciones
SELECT
    id_paciente,
    COUNT(*) AS num_cancelaciones,
    MIN(fecha_cita) AS primera_cancelacion,
    MAX(fecha_cita) AS ultima_cancelacion
FROM CITA_F5
GROUP BY id_paciente
HAVING COUNT(*) >= 1
ORDER BY num_cancelaciones DESC
LIMIT 10;
