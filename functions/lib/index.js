"use strict";
Object.defineProperty(exports, "__esModule", { value: true });
exports.send30MinuteSessionReminders = exports.send24HourSessionReminders = exports.sendNotification = exports.onSesionTutoriaCreated = exports.onSolicitudTutoriaUpdated = exports.onSolicitudTutoriaCreated = exports.onSolicitudReprogramacionPendiente = exports.onSolicitudReprogramacionAceptada = exports.onSolicitudReprogramacionRechazada = void 0;
const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();
const db = admin.firestore();
const messaging = admin.messaging();
// Nueva función centralizada para crear el documento de notificación Y enviar el push
async function createNotificationAndSendPush(userId, title, body, tipo, data) {
    try {
        // 1. Crear el documento en la colección 'notificaciones'
        const notificationRef = db.collection('notificaciones').doc();
        await notificationRef.set({
            id: notificationRef.id,
            usuarioId: userId,
            titulo: title,
            mensaje: body,
            tipo: tipo,
            fechaCreacion: admin.firestore.FieldValue.serverTimestamp(),
            leida: false,
            datosAdicionales: data,
        });
        console.log(`Documento de notificación ${notificationRef.id} creado para ${userId}`);
        // 2. Enviar la notificación push al dispositivo
        await sendPushNotification(userId, title, body, Object.assign(Object.assign({}, data), { notificationId: notificationRef.id }));
    }
    catch (error) {
        console.error('Error en createNotificationAndSendPush:', error);
    }
}
// Función que únicamente envía el push (no crea documentos)
async function sendPushNotification(userId, title, body, data) {
    try {
        // Obtener el FCM token del usuario desde la colección 'users'
        const userDoc = await db.collection('users').doc(userId).get();
        if (!userDoc.exists) {
            console.log(`Usuario ${userId} no encontrado en 'users' para enviar push.`);
            return;
        }
        const userData = userDoc.data();
        const fcmToken = userData === null || userData === void 0 ? void 0 : userData.fcmToken;
        if (!fcmToken) {
            console.log(`No hay FCM token para el usuario ${userId}`);
            return;
        }
        // Componer el mensaje
        const message = {
            token: fcmToken,
            notification: {
                title: title,
                body: body,
            },
            data: data || {},
            android: {
                notification: {
                    channelId: 'tutoring_app_channel',
                    priority: 'high',
                },
            },
            apns: {
                payload: {
                    aps: {
                        sound: 'default',
                        badge: 1,
                    },
                },
            },
        };
        // Enviar
        const response = await messaging.send(message);
        console.log(`Notificación push enviada exitosamente a ${userId}: ${response}`);
    }
    catch (error) {
        console.error(`Error enviando notificación push a ${userId}:`, error);
    }
}
// === TRIGGERS (Ahora usan la función centralizada) ===
// Trigger cuando un estudiante crea una nueva solicitud para un tutor
exports.onSolicitudTutoriaCreated = functions.firestore
    .document('solicitudes_tutoria/{solicitudId}')
    .onCreate(async (snap, context) => {
    const solicitud = snap.data();
    const estudianteDoc = await db.collection('estudiantes').doc(solicitud.estudianteId).get();
    const estudianteData = estudianteDoc.data();
    const nombreEstudiante = estudianteData
        ? `${estudianteData.nombre} ${estudianteData.apellidos}`.trim()
        : 'Estudiante';
    await createNotificationAndSendPush(solicitud.tutorId, // Notificar al TUTOR
    'Nueva solicitud de tutoría', `${nombreEstudiante} solicita una tutoría de ${solicitud.curso}`, 'solicitudTutoria', {
        solicitudId: context.params.solicitudId,
        estudianteId: solicitud.estudianteId,
        materia: solicitud.curso,
    });
});
// Trigger cuando un tutor acepta/rechaza una solicitud
exports.onSolicitudTutoriaUpdated = functions.firestore
    .document('solicitudes_tutoria/{solicitudId}')
    .onUpdate(async (change, context) => {
    const solicitudAnterior = change.before.data();
    const solicitudNueva = change.after.data();
    // Salir si el estado no cambió, o si el estado es 'aceptada'
    // El caso de 'aceptada' se maneja en 'onSesionTutoriaCreated'
    if (solicitudAnterior.estado === solicitudNueva.estado ||
        solicitudNueva.estado === 'aceptada') {
        return null;
    }
    // Solo procesar el rechazo si el estado anterior NO era 'reprogramacion_pendiente'
    if (solicitudNueva.estado === 'cancelada' && solicitudAnterior.estado !== 'reprogramacion_pendiente') {
      const tutorDoc = await db.collection('tutores').doc(solicitudNueva.tutorId).get();
      const tutorData = tutorDoc.data();
      const nombreTutor = tutorData
          ? `${tutorData.nombre} ${tutorData.apellidos}`.trim()
          : 'Tutor';
      await createNotificationAndSendPush(solicitudNueva.estudianteId, // Notificar al ESTUDIANTE
      'Solicitud rechazada', `${nombreTutor} rechazó tu solicitud de tutoría de ${solicitudNueva.curso}`, 'respuestaSolicitud', {
          solicitudId: context.params.solicitudId,
          tutorId: solicitudNueva.tutorId,
          materia: solicitudNueva.curso,
          aceptada: 'false',
      });
    }
    return null;
});
// Trigger cuando una solicitud aceptada crea una nueva sesión
exports.onSesionTutoriaCreated = functions.firestore
    .document('sesiones_tutoria/{sesionId}')
    .onCreate(async (snap, context) => {
    const sesion = snap.data();
    const tutorDoc = await db.collection('tutores').doc(sesion.tutorId).get();
    const tutorData = tutorDoc.data();
    const nombreTutor = tutorData
        ? `${tutorData.nombre} ${tutorData.apellidos}`.trim()
        : 'Tutor';
    await createNotificationAndSendPush(sesion.estudianteId, // Notificar al ESTUDIANTE
    'Sesión de tutoría confirmada', `Tu sesión de ${sesion.curso} con ${nombreTutor} ha sido confirmada.`, 'sesionConfirmada', {
        sesionId: context.params.sesionId,
        tutorId: sesion.tutorId,
        materia: sesion.curso,
    });
});
// Trigger para notificar al tutor cuando una solicitud pasa a estado 'reprogramacion_pendiente'
exports.onSolicitudReprogramacionPendiente = functions.firestore
    .document('solicitudes_tutoria/{solicitudId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    // Detectar cambio a estado 'reprogramacion_pendiente'
    if (
        before.estado !== 'reprogramacion_pendiente' &&
        after.estado === 'reprogramacion_pendiente'
    ) {
        // Obtener datos del estudiante
        const estudianteDoc = await db.collection('estudiantes').doc(after.estudianteId).get();
        const estudianteData = estudianteDoc.data();
        const nombreEstudiante = estudianteData
            ? `${estudianteData.nombre} ${estudianteData.apellidos}`.trim()
            : 'Estudiante';
        // Datos de la nueva fecha/hora propuesta
        const repro = after.reprogramacionPendiente || {};
        let fechaStr = '';
        if (repro && repro.fechaSesion) {
            let fechaObj;
            if (typeof repro.fechaSesion.toDate === 'function') {
                fechaObj = repro.fechaSesion.toDate();
            }
            else if (repro.fechaSesion._seconds) {
                fechaObj = new Date(repro.fechaSesion._seconds * 1000);
            }
            else if (typeof repro.fechaSesion === 'string' || typeof repro.fechaSesion === 'number') {
                fechaObj = new Date(repro.fechaSesion);
            }
            if (fechaObj && !isNaN(fechaObj.getTime())) {
                const opciones = {
                    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', timeZone: 'America/Lima'
                };
                fechaStr = fechaObj.toLocaleDateString('es-PE', opciones);
                fechaStr = fechaStr.charAt(0).toUpperCase() + fechaStr.slice(1);
            }
        }
        const nuevaHoraInicio = repro.horaInicio || '';
        const nuevaHoraFin = repro.horaFin || '';
        const nuevoDia = repro.dia || '';
        // Mensaje para el tutor
        const body = `${nombreEstudiante} solicita reprogramar la tutoría para el ${nuevoDia} ${fechaStr}, ${nuevaHoraInicio} - ${nuevaHoraFin}`;
        await createNotificationAndSendPush(
            after.tutorId,
            'Solicitud de reprogramación',
            body,
            'reprogramacionPendiente',
            {
                solicitudId: context.params.solicitudId,
                estudianteId: after.estudianteId,
                materia: after.curso,
                nuevaFecha: fechaStr,
                nuevaHoraInicio,
                nuevaHoraFin,
                nuevoDia,
            }
        );
    }
    return null;
});
// Notificar al estudiante cuando el tutor ACEPTA la reprogramación
exports.onSolicitudReprogramacionAceptada = functions.firestore
    .document('solicitudes_tutoria/{solicitudId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (
        before.estado === 'reprogramacion_pendiente' &&
        after.estado === 'aceptada'
    ) {
        // Datos de la nueva fecha/hora
        let fechaStr = '';
        if (after.fechaSesion) {
            let fechaObj;
            if (typeof after.fechaSesion.toDate === 'function') {
                fechaObj = after.fechaSesion.toDate();
            }
            else if (after.fechaSesion._seconds) {
                fechaObj = new Date(after.fechaSesion._seconds * 1000);
            }
            else if (typeof after.fechaSesion === 'string' || typeof after.fechaSesion === 'number') {
                fechaObj = new Date(after.fechaSesion);
            }
            if (fechaObj && !isNaN(fechaObj.getTime())) {
                const opciones = {
                    weekday: 'long', year: 'numeric', month: 'long', day: 'numeric', timeZone: 'America/Lima'
                };
                fechaStr = fechaObj.toLocaleDateString('es-PE', opciones);
                fechaStr = fechaStr.charAt(0).toUpperCase() + fechaStr.slice(1);
            }
        }
        const nuevaHoraInicio = after.horaInicio || '';
        const nuevaHoraFin = after.horaFin || '';
        const nuevoDia = after.dia || '';
        const body = `El tutor aceptó la reprogramación. Nueva fecha: ${nuevoDia} ${fechaStr}, ${nuevaHoraInicio} - ${nuevaHoraFin}`;
        await createNotificationAndSendPush(
            after.estudianteId,
            'Reprogramación aceptada',
            body,
            'reprogramacionAceptada',
            {
                solicitudId: context.params.solicitudId,
                tutorId: after.tutorId,
                materia: after.curso,
                nuevaFecha: fechaStr,
                nuevaHoraInicio,
                nuevaHoraFin,
                nuevoDia,
            }
        );
    }
    return null;
});
// Notificar al estudiante cuando el tutor RECHAZA la reprogramación
exports.onSolicitudReprogramacionRechazada = functions.firestore
    .document('solicitudes_tutoria/{solicitudId}')
    .onUpdate(async (change, context) => {
    const before = change.before.data();
    const after = change.after.data();
    if (
        before.estado === 'reprogramacion_pendiente' &&
        after.estado === 'cancelada'
    ) {
        const body = `El tutor rechazó la reprogramación. La tutoría ha sido cancelada.`;
        await createNotificationAndSendPush(
            after.estudianteId,
            'Reprogramación rechazada',
            body,
            'reprogramacionRechazada',
            {
                solicitudId: context.params.solicitudId,
                tutorId: after.tutorId,
                materia: after.curso,
            }
        );
    }
    return null;
});
// Función HTTP para enviar notificaciones manuales (ej. desde panel admin)
exports.sendNotification = functions.https.onCall(async (data, context) => {
    var _a;
    if (!context.auth) {
        throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado');
    }
    const { userId, title, body, notificationData } = data;
    const userDoc = await db.collection('users').doc(context.auth.uid).get();
    const userRole = (_a = userDoc.data()) === null || _a === void 0 ? void 0 : _a.role;
    if (userRole !== 'admin' && userRole !== 'superAdmin') {
        throw new functions.https.HttpsError('permission-denied', 'Sin permisos');
    }
    await createNotificationAndSendPush(userId, title, body, 'manual', notificationData);
    return { success: true };
});
// === FUNCIONES PROGRAMADAS (CRON JOBS) ===
// 1. Recordatorio 24 horas antes de la sesión
exports.send24HourSessionReminders = functions.pubsub
    .schedule('every 1 hours')
    .onRun(async (context) => {
    const now = new Date();
    const twentyFourHoursFromNow = new Date(now.getTime() + 24 * 60 * 60 * 1000);
    const twentyFiveHoursFromNow = new Date(now.getTime() + 25 * 60 * 60 * 1000);
    const sesionesSnapshot = await db.collection('sesiones_tutoria')
        .where('fechaSesion', '>=', twentyFourHoursFromNow)
        .where('fechaSesion', '<', twentyFiveHoursFromNow)
        .where('estado', '==', 'aceptada')
        .get();
    if (sesionesSnapshot.empty) {
        console.log('No hay sesiones para recordar con 24h de antelación.');
        return null;
    }
    for (const doc of sesionesSnapshot.docs) {
        const sesion = doc.data();
        const [tutorDoc, estudianteDoc] = await Promise.all([
            db.collection('tutores').doc(sesion.tutorId).get(),
            db.collection('estudiantes').doc(sesion.estudianteId).get(),
        ]);
        const nombreTutor = tutorDoc.data() ? `${tutorDoc.data().nombre} ${tutorDoc.data().apellidos}`.trim() : 'Tutor';
        const nombreEstudiante = estudianteDoc.data() ? `${estudianteDoc.data().nombre} ${estudianteDoc.data().apellidos}`.trim() : 'Estudiante';
        const datosNotificacion = {
            sesionId: doc.id,
            tutorId: sesion.tutorId,
            estudianteId: sesion.estudianteId,
            materia: sesion.curso,
        };
        // Notificar al estudiante
        await createNotificationAndSendPush(sesion.estudianteId, 'Recordatorio de sesión', `Tu sesión de ${sesion.curso} con ${nombreTutor} es mañana.`, 'recordatorioSesion', datosNotificacion);
        // Notificar al tutor
        await createNotificationAndSendPush(sesion.tutorId, 'Recordatorio de sesión', `Tu sesión de ${sesion.curso} con ${nombreEstudiante} es mañana.`, 'recordatorioSesion', datosNotificacion);
    }
    console.log(`Enviados ${sesionesSnapshot.docs.length * 2} recordatorios de 24h.`);
    return null;
});
// 2. Recordatorio 30 minutos antes de la sesión
exports.send30MinuteSessionReminders = functions.pubsub
    .schedule('every 15 minutes') // Más granularidad para recordatorios cercanos
    .onRun(async (context) => {
    const now = new Date();
    const thirtyMinutesFromNow = new Date(now.getTime() + 30 * 60 * 1000);
    const sesionesSnapshot = await db.collection('sesiones_tutoria')
        .where('fechaSesion', '>=', now)
        .where('fechaSesion', '<=', thirtyMinutesFromNow)
        .where('estado', '==', 'aceptada')
        .get();
    if (sesionesSnapshot.empty) {
        console.log('No hay sesiones para recordar con 30min de antelación.');
        return null;
    }
    for (const doc of sesionesSnapshot.docs) {
        const sesion = doc.data();
        const [tutorDoc, estudianteDoc] = await Promise.all([
            db.collection('tutores').doc(sesion.tutorId).get(),
            db.collection('estudiantes').doc(sesion.estudianteId).get(),
        ]);
        const nombreTutor = tutorDoc.data() ? `${tutorDoc.data().nombre} ${tutorDoc.data().apellidos}`.trim() : 'Tutor';
        const nombreEstudiante = estudianteDoc.data() ? `${estudianteDoc.data().nombre} ${estudianteDoc.data().apellidos}`.trim() : 'Estudiante';
        const datosNotificacion = {
            sesionId: doc.id,
            tutorId: sesion.tutorId,
            estudianteId: sesion.estudianteId,
            materia: sesion.curso,
        };
        // Notificar al estudiante
        await createNotificationAndSendPush(sesion.estudianteId, 'Tu sesión comienza pronto', `Tu sesión de ${sesion.curso} con ${nombreTutor} es en 30 minutos.`, 'recordatorioSesion', datosNotificacion);
        // Notificar al tutor
        await createNotificationAndSendPush(sesion.tutorId, 'Tu sesión comienza pronto', `Tu sesión de ${sesion.curso} con ${nombreEstudiante} es en 30 minutos.`, 'recordatorioSesion', datosNotificacion);
    }
    console.log(`Enviados ${sesionesSnapshot.docs.length * 2} recordatorios de 30min.`);
    return null;
});
//# sourceMappingURL=index.js.map