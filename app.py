import os
from dotenv import load_dotenv
load_dotenv()

from flask import Flask, render_template, request, redirect, url_for, flash, jsonify
from db import query, execute, ping, ping_all
from config import NODOS

app = Flask(__name__)
app.secret_key = "sgcm-secret-2026"

def estado_nodos():
    return ping_all()

@app.route("/")
def index():
    estado = estado_nodos()
    return render_template("index.html", nodos=NODOS, estado=estado)

@app.route("/api/estado")
def api_estado():
    return jsonify({nid: ping(nid) for nid in NODOS})

@app.route("/pacientes")
def pacientes():
    v1 = query(1, "SELECT id_paciente, nombre, apellido_p, apellido_m, telefono, email, activo FROM PACIENTE_V1 ORDER BY id_paciente")
    v2 = query(2, "SELECT id_paciente, nombre, apellido_p, fecha_nac, sexo, tipo_sangre FROM PACIENTE_V2 ORDER BY id_paciente")
    v3 = query(5, "SELECT id_paciente, sexo, tipo_sangre, fecha_registro, activo FROM PACIENTE_V3 ORDER BY id_paciente")
    estado = estado_nodos()
    return render_template("pacientes.html", v1=v1, v2=v2, v3=v3, estado=estado, nodos=NODOS)

@app.route("/pacientes/agregar", methods=["GET", "POST"])
def paciente_agregar():
    if request.method == "POST":
        f = request.form
        pid = int(f["id_paciente"])

        ok1, _ = execute(1,
            "INSERT INTO PACIENTE_V1 (id_paciente, nombre, apellido_p, apellido_m, telefono, email, activo) "
            "VALUES (%s, %s, %s, %s, %s, %s, 1)",
            (pid, f["nombre"], f["apellido_p"], f.get("apellido_m",""),
             f.get("telefono",""), f.get("email",""))
        )
        ok2, _ = execute(2,
            "INSERT INTO PACIENTE_V2 (id_paciente, nombre, apellido_p, apellido_m, fecha_nac, sexo, tipo_sangre, fecha_registro) "
            "VALUES (%s, %s, %s, %s, %s, %s, %s, CURDATE())",
            (pid, f["nombre"], f["apellido_p"], f.get("apellido_m",""),
             f["fecha_nac"], f["sexo"], f.get("tipo_sangre",""))
        )
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
    execute(1, "DELETE FROM PACIENTE_V1 WHERE id_paciente = %s", (pid,))
    execute(2, "DELETE FROM PACIENTE_V2 WHERE id_paciente = %s", (pid,))
    execute(5, "DELETE FROM PACIENTE_V3 WHERE id_paciente = %s", (pid,))
    flash(f"Paciente #{pid} eliminado de los 3 nodos.", "warning")
    return redirect(url_for("pacientes"))

@app.route("/pacientes/datos/<int:pid>")
def paciente_datos(pid):
    datos = {}
    v1 = query(1, "SELECT * FROM PACIENTE_V1 WHERE id_paciente=%s", (pid,))
    v2 = query(2, "SELECT * FROM PACIENTE_V2 WHERE id_paciente=%s", (pid,))
    v3 = query(5, "SELECT * FROM PACIENTE_V3 WHERE id_paciente=%s", (pid,))
    if v1: datos.update(v1[0])
    if v2: datos.update(v2[0])
    if v3: datos.update(v3[0])
    return jsonify(datos)

@app.route("/pacientes/editar/<int:pid>", methods=["POST"])
def paciente_editar(pid):
    f = request.form
    ok1, _ = execute(1,
        "UPDATE PACIENTE_V1 SET nombre=%s, apellido_p=%s, apellido_m=%s, "
        "telefono=%s, email=%s, activo=%s WHERE id_paciente=%s",
        (f["nombre"], f["apellido_p"], f.get("apellido_m",""),
         f.get("telefono",""), f.get("email",""), int(f.get("activo",1)), pid))
    ok2, _ = execute(2,
        "UPDATE PACIENTE_V2 SET nombre=%s, apellido_p=%s, apellido_m=%s, "
        "fecha_nac=%s, sexo=%s, tipo_sangre=%s WHERE id_paciente=%s",
        (f["nombre"], f["apellido_p"], f.get("apellido_m",""),
         f["fecha_nac"], f["sexo"], f.get("tipo_sangre",""), pid))
    ok3, _ = execute(5,
        "UPDATE PACIENTE_V3 SET sexo=%s, tipo_sangre=%s, activo=%s WHERE id_paciente=%s",
        (f["sexo"], f.get("tipo_sangre",""), int(f.get("activo",1)), pid))
    for nombre, ok in [("N1 Contacto", ok1), ("N2 Clinico", ok2), ("N5 Estadistico", ok3)]:
        flash(f"{'OK' if ok else 'FAIL'} {nombre}", "success" if ok else "danger")
    return redirect(url_for("pacientes"))

@app.route("/pacientes/v3/eliminar/<int:pid>", methods=["POST"])
def paciente_v3_eliminar(pid):
    ok, _ = execute(5, "DELETE FROM PACIENTE_V3 WHERE id_paciente=%s", (pid,))
    flash(f"PACIENTE_V3 #{pid} eliminado de Nodo 5" if ok else "Error al eliminar", "success" if ok else "danger")
    return redirect(url_for("pacientes"))

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
    f = request.form
    estatus    = f["estatus"]
    fecha_str  = f["fecha_cita"]
    fecha_mes  = int(fecha_str[5:7])  # YYYY-MM-DD → mes
    fecha_anio = int(fecha_str[:4])

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

@app.route("/citas/datos/<int:nodo>/<int:cid>")
def cita_datos(nodo, cid):
    rows = query(nodo, f"SELECT * FROM CITA_F{nodo} WHERE id_cita=%s", (cid,))
    return jsonify(rows[0] if rows else {})

@app.route("/citas/editar/<int:nodo>/<int:cid>", methods=["POST"])
def cita_editar(nodo, cid):
    f = request.form
    ok, err = execute(nodo,
        f"UPDATE CITA_F{nodo} SET id_paciente=%s, id_medico=%s, fecha_cita=%s, "
        f"hora_cita=%s, motivo=%s, estatus=%s WHERE id_cita=%s",
        (f["id_paciente"], f["id_medico"], f["fecha_cita"],
         f["hora_cita"], f.get("motivo",""), f["estatus"], cid))
    if ok:
        flash(f"✓ Cita #{cid} actualizada en Nodo {nodo}", "success")
    else:
        flash(f"✗ Error al actualizar cita #{cid}: {err}", "danger")
    return redirect(url_for("citas"))

@app.route("/citas/eliminar/<int:nodo>/<int:cid>", methods=["POST"])
def cita_eliminar(nodo, cid):
    ok, err = execute(nodo, f"DELETE FROM CITA_F{nodo} WHERE id_cita=%s", (cid,))
    if ok:
        flash(f"✓ Cita #{cid} eliminada de Nodo {nodo}", "success")
    else:
        flash(f"✗ Error al eliminar cita #{cid}: {err}", "danger")
    return redirect(url_for("citas"))

# MEDICOS
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

@app.route("/medicos/datos/<int:id>")
def medico_datos(id):
    rows = query(1, "SELECT * FROM MEDICO WHERE id_medico=%s", (id,))
    return jsonify(rows[0] if rows else {})

@app.route("/medicos/editar/<int:id>", methods=["POST"])
def medico_editar(id):
    f = request.form
    ok, err = execute(1,
        "UPDATE MEDICO SET nombre=%s, apellido_p=%s, apellido_m=%s, cedula=%s, "
        "telefono=%s, email=%s, id_especialidad=%s, turno=%s WHERE id_medico=%s",
        (f["nombre"], f["apellido_p"], f.get("apellido_m",""), f["cedula"],
         f.get("telefono",""), f.get("email",""), f["id_especialidad"],
         f["turno"], id))
    flash(f"✓ Médico #{id} actualizado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("medicos"))

@app.route("/medicos/eliminar/<int:id>", methods=["POST"])
def medico_eliminar(id):
    ok, err = execute(1, "DELETE FROM MEDICO WHERE id_medico=%s", (id,))
    flash(f"✓ Médico #{id} eliminado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("medicos"))

# FARMACIA
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

@app.route("/farmacia/medicamento/agregar", methods=["POST"])
def medicamento_agregar():
    f = request.form
    ok, err = execute(3,
        "INSERT INTO MEDICAMENTO (nombre, presentacion, dosis_std, stock, precio) "
        "VALUES (%s, %s, %s, %s, %s)",
        (f["nombre"], f["presentacion"], f.get("dosis_std",""),
         int(f["stock"]), float(f["precio"])))
    flash(f"✓ Medicamento registrado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("farmacia"))

@app.route("/farmacia/medicamento/datos/<int:id>")
def medicamento_datos(id):
    rows = query(3, "SELECT * FROM MEDICAMENTO WHERE id_medicamento=%s", (id,))
    return jsonify(rows[0] if rows else {})

@app.route("/farmacia/medicamento/editar/<int:id>", methods=["POST"])
def medicamento_editar(id):
    f = request.form
    ok, err = execute(3,
        "UPDATE MEDICAMENTO SET nombre=%s, presentacion=%s, dosis_std=%s, stock=%s, precio=%s WHERE id_medicamento=%s",
        (f["nombre"], f["presentacion"], f.get("dosis_std",""), int(f["stock"]), float(f["precio"]), id))
    flash(f"✓ Medicamento #{id} actualizado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("farmacia"))

@app.route("/farmacia/medicamento/eliminar/<int:id>", methods=["POST"])
def medicamento_eliminar(id):
    ok, err = execute(3, "DELETE FROM MEDICAMENTO WHERE id_medicamento=%s", (id,))
    flash(f"✓ Medicamento #{id} eliminado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("farmacia"))

# ADMINISTRACION
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
    execute(4,
        "UPDATE FACTURA SET estatus_pago = 'pagado' WHERE id_factura = %s",
        (id_factura,)
    )
    ok, err = execute(4,
        "INSERT INTO PAGO (id_factura, fecha_pago, monto, metodo_pago) "
        "VALUES (%s, CURDATE(), %s, %s)",
        (id_factura, f["monto"], f["metodo_pago"])
    )
    flash("✓ Pago registrado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("admin"))

@app.route("/admin/factura/agregar", methods=["POST"])
def factura_agregar():
    f = request.form
    total = float(f["subtotal"]) * 1.16
    iva = total - float(f["subtotal"])
    ok, err = execute(4,
        "INSERT INTO FACTURA (id_consulta, fecha_emision, subtotal, iva, total, estatus_pago) "
        "VALUES (%s, %s, %s, %s, %s, 'pendiente')",
        (f["id_consulta"], f["fecha_emision"], float(f["subtotal"]), iva, total))
    flash("✓ Factura creada" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("admin"))

@app.route("/admin/factura/eliminar/<int:id>", methods=["POST"])
def factura_eliminar(id):
    execute(4, "DELETE FROM PAGO WHERE id_factura=%s", (id,))
    ok, err = execute(4, "DELETE FROM FACTURA WHERE id_factura=%s", (id,))
    flash(f"✓ Factura #{id} eliminada" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("admin"))

@app.route("/admin/pago/eliminar/<int:id>", methods=["POST"])
def pago_eliminar(id):
    ok, err = execute(4, "DELETE FROM PAGO WHERE id_pago=%s", (id,))
    flash(f"✓ Pago #{id} eliminado" if ok else f"✗ Error: {err}",
          "success" if ok else "danger")
    return redirect(url_for("admin"))

# REPORTES
@app.route("/reportes")
def reportes():
    # Demografía por tipo de sangre
    demografia_sangre = query(5, """
        SELECT tipo_sangre, COUNT(*) AS total,
               ROUND(COUNT(*) * 100.0 / (SELECT COUNT(*) FROM PACIENTE_V3 WHERE activo=1), 1) AS porcentaje
        FROM PACIENTE_V3 WHERE activo=1
        GROUP BY tipo_sangre ORDER BY total DESC
    """)
    # Demografía por sexo
    demografia_sexo = query(5, """
        SELECT CASE sexo WHEN 'M' THEN 'Masculino' ELSE 'Femenino' END AS genero,
               COUNT(*) AS total
        FROM PACIENTE_V3 WHERE activo=1 GROUP BY sexo
    """)
    # Cancelaciones por mes
    cancelaciones_mes = query(5, """
        SELECT YEAR(fecha_cita) AS anio, MONTH(fecha_cita) AS mes,
               COUNT(*) AS total_cancelaciones
        FROM CITA_F5 GROUP BY anio, mes ORDER BY anio, mes
    """)
    # Top canceladores
    top_canceladores = query(5, """
        SELECT id_paciente, COUNT(*) AS num_cancelaciones,
               MIN(fecha_cita) AS primera, MAX(fecha_cita) AS ultima
        FROM CITA_F5 GROUP BY id_paciente
        ORDER BY num_cancelaciones DESC LIMIT 10
    """)
    # Crecimiento de pacientes
    crecimiento = query(5, """
        SELECT YEAR(fecha_registro) AS anio, MONTH(fecha_registro) AS mes,
               COUNT(*) AS nuevos
        FROM PACIENTE_V3 GROUP BY anio, mes ORDER BY anio, mes
    """)
    # Datos para CRUD
    v3_list = query(5, "SELECT * FROM PACIENTE_V3 ORDER BY id_paciente")
    f5_list = query(5, "SELECT * FROM CITA_F5 ORDER BY id_cita")
    estado = estado_nodos()
    return render_template("reportes.html",
                           demografia_sangre=demografia_sangre,
                           demografia_sexo=demografia_sexo,
                           cancelaciones_mes=cancelaciones_mes,
                           top_canceladores=top_canceladores,
                           crecimiento=crecimiento,
                           v3_list=v3_list, f5_list=f5_list,
                           estado=estado, nodos=NODOS)

@app.route("/reportes/v3/agregar", methods=["POST"])
def v3_agregar():
    f = request.form
    ok, err = execute(5,
        "INSERT INTO PACIENTE_V3 (id_paciente, sexo, tipo_sangre, fecha_registro, activo) "
        "VALUES (%s, %s, %s, %s, %s)",
        (f["id_paciente"], f["sexo"], f.get("tipo_sangre",""), f["fecha_registro"], int(f.get("activo",1))))
    flash("✓ Paciente V3 registrado" if ok else f"✗ Error: {err}", "success" if ok else "danger")
    return redirect(url_for("reportes"))

@app.route("/reportes/v3/editar/<int:pid>", methods=["POST"])
def v3_editar(pid):
    f = request.form
    ok, err = execute(5,
        "UPDATE PACIENTE_V3 SET sexo=%s, tipo_sangre=%s, fecha_registro=%s, activo=%s WHERE id_paciente=%s",
        (f["sexo"], f.get("tipo_sangre",""), f["fecha_registro"], int(f.get("activo",1)), pid))
    flash("✓ Paciente V3 actualizado" if ok else f"✗ Error: {err}", "success" if ok else "danger")
    return redirect(url_for("reportes"))

@app.route("/reportes/v3/eliminar/<int:pid>", methods=["POST"])
def v3_eliminar(pid):
    ok, err = execute(5, "DELETE FROM PACIENTE_V3 WHERE id_paciente=%s", (pid,))
    flash("✓ Paciente V3 eliminado" if ok else f"✗ Error: {err}", "success" if ok else "danger")
    return redirect(url_for("reportes"))

@app.route("/reportes/f5/agregar", methods=["POST"])
def f5_agregar():
    f = request.form
    ok, err = execute(5,
        "INSERT INTO CITA_F5 (id_paciente, id_medico, fecha_cita, hora_cita, motivo, estatus) "
        "VALUES (%s, %s, %s, %s, %s, 'cancelada')",
        (f["id_paciente"], f["id_medico"], f["fecha_cita"], f["hora_cita"], f.get("motivo","")))
    flash("✓ Cita cancelada registrada" if ok else f"✗ Error: {err}", "success" if ok else "danger")
    return redirect(url_for("reportes"))

@app.route("/reportes/f5/eliminar/<int:cid>", methods=["POST"])
def f5_eliminar(cid):
    ok, err = execute(5, "DELETE FROM CITA_F5 WHERE id_cita=%s", (cid,))
    flash("✓ Cita cancelada eliminada" if ok else f"✗ Error: {err}", "success" if ok else "danger")
    return redirect(url_for("reportes"))

if __name__ == "__main__":
    import os
    port = int(os.environ.get("SGCM_PORT", 5050))
    print(f" SGCM iniciado en http://0.0.0.0:{port}")
    print(f" Acceso local:    http://localhost:{port}")
    print(f" Red Hamachi:     http://<tu-ip-hamachi>:{port}")
    print(f" Nodos configurados: {len(NODOS)}")
    app.run(host="0.0.0.0", port=port)
