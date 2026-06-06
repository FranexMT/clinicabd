# app.py
from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from db import query, execute, ping_all
from config import NODOS

app = Flask(__name__)
app.secret_key = "sgcm-secret-2026"

# ─── utilidad: estado de todos los nodos ────────────────────
def estado_nodos():
    return ping_all()

# ════════════════════════════════════════════════════════════
# INICIO — panel de estado de los 5 nodos
# ════════════════════════════════════════════════════════════
@app.route("/")
def index():
    estado = estado_nodos()
    return render_template("index.html", nodos=NODOS, estado=estado)

@app.route("/api/estado")
def api_estado():
    """Endpoint JSON para refrescar el estado de nodos sin recargar."""
    return jsonify({nid: ping(nid) for nid in NODOS})

# ════════════════════════════════════════════════════════════
# PACIENTES — fragmentos V1 (Nodo1) + V2 (Nodo2) + V3 (Nodo5)
# ════════════════════════════════════════════════════════════
@app.route("/pacientes")
def pacientes():
    v1 = query(1, "SELECT id_paciente, nombre, apellido_p, apellido_m, telefono, email, activo FROM PACIENTE_V1 ORDER BY id_paciente")
    v2 = query(2, "SELECT id_paciente, nombre, apellido_p, fecha_nac, sexo, tipo_sangre FROM PACIENTE_V2 ORDER BY id_paciente")
    v3 = query(5, "SELECT id_paciente, sexo, tipo_sangre, fecha_registro, activo FROM PACIENTE_V3 ORDER BY id_paciente")
    estado = estado_nodos()
    return render_template("pacientes.html", v1=v1, v2=v2, v3=v3, estado=estado, nodos=NODOS)

@app.route("/pacientes/agregar", methods=["GET", "POST"])
def paciente_agregar():
    """
    Agrega un paciente nuevo en los 3 fragmentos verticales.
    Nodo1 = contacto, Nodo2 = clínico, Nodo5 = estadístico.
    """
    if request.method == "POST":
        f = request.form
        pid = int(f["id_paciente"])

        # Nodo 1 — PACIENTE_V1 (contacto)
        ok1, _ = execute(1,
            "INSERT INTO PACIENTE_V1 (id_paciente, nombre, apellido_p, apellido_m, telefono, email, activo) "
            "VALUES (%s, %s, %s, %s, %s, %s, 1)",
            (pid, f["nombre"], f["apellido_p"], f.get("apellido_m",""),
             f.get("telefono",""), f.get("email",""))
        )
        # Nodo 2 — PACIENTE_V2 (clínico)
        ok2, _ = execute(2,
            "INSERT INTO PACIENTE_V2 (id_paciente, nombre, apellido_p, apellido_m, fecha_nac, sexo, tipo_sangre, fecha_registro) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, CURDATE())",
            (pid, f["nombre"], f["apellido_p"], f.get("apellido_m",""),
             f["fecha_nac"], f["sexo"], f.get("tipo_sangre",""))
        )
        # Nodo 5 — PACIENTE_V3 (estadístico)
        ok3, _ = execute(5,
            "INSERT INTO PACIENTE_V3 (id_paciente, sexo, tipo_sangre, fecha_registro, activo) "
            "VALUES (%s, %s, %s, CURDATE(), 1)",
            (pid, f["sexo"], f.get("tipo_sangre",""))
        )

        resultados = [("Nodo1 Contacto", ok1), ("Nodo2 Clínico", ok2), ("Nodo5 Estadístico", ok3)]
        for nombre, ok in resultados:
            if ok:
                flash(f"✓ {nombre}: paciente registrado", "success")
            else:
                flash(f"✗ {nombre}: no se pudo registrar (nodo caído o datos duplicados)", "danger")

        return redirect(url_for("pacientes"))

    return render_template("pacientes.html",
                           v1=[], v2=[], v3=[],
                           estado=estado_nodos(), nodos=NODOS,
                           mostrar_form=True)

@app.route("/pacientes/eliminar/<int:pid>", methods=["POST"])
def paciente_eliminar(pid):
    """Elimina el paciente de los 3 fragmentos verticales."""
    execute(1, "DELETE FROM PACIENTE_V1 WHERE id_paciente = %s", (pid,))
    execute(2, "DELETE FROM PACIENTE_V2 WHERE id_paciente = %s", (pid,))
    execute(5, "DELETE FROM PACIENTE_V3 WHERE id_paciente = %s", (pid,))
    flash(f"Paciente #{pid} eliminado de los 3 nodos.", "warning")
    return redirect(url_for("pacientes"))

# ════════════════════════════════════════════════════════════
# CITAS — fragmentos F1–F5 repartidos en Nodos 1,2,3,4,5
# ════════════════════════════════════════════════════════════
@app.route("/citas")
def citas():
    f1 = query(1, "SELECT id_cita, id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus FROM CITA_F1 ORDER BY fecha_cita")
    f2 = query(2, "SELECT id_cita, id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus FROM CITA_F2 ORDER BY fecha_cita")
    f3 = query(3, "SELECT id_cita, id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus FROM CITA_F3 ORDER BY fecha_cita")
    f4 = query(4, "SELECT id_cita, id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus FROM CITA_F4 ORDER BY fecha_cita")
    f5 = query(5, "SELECT id_cita, id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus FROM CITA_F5 ORDER BY fecha_cita")
    estado = estado_nodos()
    return render_template("citas.html",
                           f1=f1, f2=f2, f3=f3, f4=f4, f5=f5,
                           estado=estado, nodos=NODOS)

@app.route("/citas/agregar", methods=["POST"])
def cita_agregar():
    """
    Agrega una cita al fragmento correcto según estatus y fecha.
    F1 = programada 2026-01 a 2026-06  (Nodo1)
    F2 = programada 2026-07 a 2026-12  (Nodo2)
    F3 = completada 2025-01 a 2025-06  (Nodo3)
    F4 = completada 2025-07 a 2025-12  (Nodo4)
    F5 = cancelada  cualquier fecha    (Nodo5)
    """
    f = request.form
    estatus    = f["estatus"]
    fecha_str  = f["fecha_cita"]
    fecha_mes  = int(fecha_str[5:7])  # YYYY-MM-DD → mes
    fecha_anio = int(fecha_str[:4])

    # Decidir nodo y tabla
    if estatus == "cancelada":
        nodo, tabla = 5, "CITA_F5"
    elif estatus == "completada" and fecha_anio == 2025 and fecha_mes <= 6:
        nodo, tabla = 3, "CITA_F3"
    elif estatus == "completada" and fecha_anio == 2025 and fecha_mes >= 7:
        nodo, tabla = 4, "CITA_F4"
    elif estatus == "programada" and fecha_anio == 2026 and fecha_mes <= 6:
        nodo, tabla = 1, "CITA_F1"
    elif estatus == "programada" and fecha_anio == 2026 and fecha_mes >= 7:
        nodo, tabla = 2, "CITA_F2"
    else:
        flash("Fecha o estatus fuera del rango de los fragmentos definidos.", "danger")
        return redirect(url_for("citas"))

    ok, err = execute(nodo,
        f"INSERT INTO {tabla} (id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus) "
        f"VALUES (%s, %s, %s, %s, %s, %s)",
        (f["id_paciente"], f["id_medico"], fecha_str,
         f["hora_cita"], f.get("motivo",""), estatus)
    )
    if ok:
        flash(f"✓ Cita registrada en Nodo {nodo} ({tabla})", "success")
    else:
        flash(f"✗ Error al registrar cita: {err}", "danger")

    return redirect(url_for("citas"))

# ════════════════════════════════════════════════════════════
# MÉDICOS — Nodo 1
# ════════════════════════════════════════════════════════════
@app.route("/medicos")
def medicos():
    medicos_  = query(1, """
        SELECT m.id_medico, m.nombre, m.apellido_p, m.cedula,
               m.telefono, m.email, e.nombre AS especialidad, m.turno
        FROM MEDICO m
        JOIN ESPECIALIDAD e ON m.id_especialidad = e.id_especialidad
        ORDER BY m.id_medico
    """)
    especialidades = query(1, "SELECT id_especialidad, nombre FROM ESPECIALIDAD ORDER BY nombre")
    estado = estado_nodos()
    return render_template("medicos.html",
                           medicos=medicos_,
                           especialidades=especialidades,
                           estado=estado, nodos=NODOS)

@app.route("/medicos/agregar", methods=["POST"])
def medico_agregar():
    f = request.form
    ok, err = execute(1,
        "INSERT INTO MEDICO (nombre, apellido_p, apellido_m, cedula, telefono, email, id_especialidad, turno) "
        "VALUES (%s, %s, %s, %s, %s, %s, %s, %s)",
        (f["nombre"], f["apellido_p"], f.get("apellido_m",""),
         f["cedula"], f.get("telefono",""), f.get("email",""),
         f["id_especialidad"], f.get("turno","matutino"))
    )
    flash(f"✓ Médico registrado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("medicos"))

# ════════════════════════════════════════════════════════════
# FARMACIA — Nodo 3 (medicamentos + recetas pendientes)
# ════════════════════════════════════════════════════════════
@app.route("/farmacia")
def farmacia():
    medicamentos = query(3,
        "SELECT id_medicamento, nombre, presentacion, dosis_std, stock, precio "
        "FROM MEDICAMENTO ORDER BY nombre"
    )
    pendientes = query(3, """
        SELECT dr.id_detalle, dr.id_receta, m.nombre AS medicamento,
               m.presentacion, dr.cantidad, dr.duracion_dias
        FROM DETALLE_RECETA dr
        JOIN MEDICAMENTO m ON m.id_medicamento = dr.id_medicamento
        WHERE dr.dispensado = 0
        ORDER BY dr.id_receta
    """)
    estado = estado_nodos()
    return render_template("farmacia.html",
                           medicamentos=medicamentos,
                           pendientes=pendientes,
                           estado=estado, nodos=NODOS)

@app.route("/farmacia/dispensar/<int:id_detalle>", methods=["POST"])
def dispensar(id_detalle):
    ok, err = execute(3,
        "UPDATE DETALLE_RECETA SET dispensado = 1 WHERE id_detalle = %s",
        (id_detalle,)
    )
    flash("✓ Medicamento dispensado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("farmacia"))

# ════════════════════════════════════════════════════════════
# ADMINISTRACIÓN — Nodo 4 (facturas + pagos)
# ════════════════════════════════════════════════════════════
@app.route("/admin")
def admin():
    facturas = query(4, """
        SELECT f.id_factura, f.id_consulta, f.fecha_emision,
               f.subtotal, f.iva, f.total, f.estatus_pago,
               c.id_paciente
        FROM FACTURA f
        JOIN CITA_F4 c ON c.id_cita = f.id_consulta
        ORDER BY f.fecha_emision DESC
    """)
    pagos = query(4,
        "SELECT id_pago, id_factura, fecha_pago, monto, metodo_pago FROM PAGO ORDER BY fecha_pago DESC"
    )
    estado = estado_nodos()
    return render_template("admin.html",
                           facturas=facturas,
                           pagos=pagos,
                           estado=estado, nodos=NODOS)

@app.route("/admin/pagar/<int:id_factura>", methods=["POST"])
def registrar_pago(id_factura):
    f = request.form
    # marcar factura como pagada
    execute(4,
        "UPDATE FACTURA SET estatus_pago = 'pagado' WHERE id_factura = %s",
        (id_factura,)
    )
    # insertar registro de pago
    ok, err = execute(4,
        "INSERT INTO PAGO (id_factura, fecha_pago, monto, metodo_pago) "
        "VALUES (%s, CURDATE(), %s, %s)",
        (id_factura, f["monto"], f["metodo_pago"])
    )
    flash("✓ Pago registrado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("admin"))

if __name__ == "__main__":
    app.run(debug=False, port=5050)
