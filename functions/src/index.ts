import * as functions from 'firebase-functions';
import * as admin from 'firebase-admin';

admin.initializeApp();

const db = admin.firestore();
const messaging = admin.messaging();

// Nueva función centralizada para crear el documento de notificación Y enviar el push
async function createNotificationAndSendPush(
  userId: string,
  title: string,
  body: string,
  tipo: string,
  data: { [key: string]: string }
) {
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
    await sendPushNotification(userId, title, body, {
      ...data,
      notificationId: notificationRef.id, // Enviar el ID del doc en los datos del push
    });
  } catch (error) {
    console.error('Error en createNotificationAndSendPush:', error);
  }
}

// Función que únicamente envía el push (no crea documentos)
async function sendPushNotification(
  userId: string,
  title: string,
  body: string,
  data?: { [key: string]: string }
) {
  try {
    // Obtener el FCM token del usuario desde la colección 'users'
    const userDoc = await db.collection('users').doc(userId).get();
    if (!userDoc.exists) {
      console.log(`Usuario ${userId} no encontrado en 'users' para enviar push.`);
      return;
    }

    const userData = userDoc.data();
    const fcmToken = userData?.fcmToken;

    if (!fcmToken) {
      console.log(`No hay FCM token para el usuario ${userId}`);
      return;
    }

    // Componer el mensaje
    const message: admin.messaging.Message = {
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
  } catch (error) {
    console.error(`Error enviando notificación push a ${userId}:`, error);
  }
}

// === TRIGGERS (Ahora usan la función centralizada) ===

// Trigger cuando un estudiante crea una nueva solicitud para un tutor
export const onSolicitudTutoriaCreated = functions.firestore
  .document('solicitudes_tutoria/{solicitudId}')
  .onCreate(async (snap, context) => {
    const solicitud = snap.data();
    const estudianteDoc = await db.collection('estudiantes').doc(solicitud.estudianteId).get();
    const estudianteData = estudianteDoc.data();
    const nombreEstudiante = estudianteData
      ? `${estudianteData.nombre} ${estudianteData.apellidos}`.trim()
      : 'Estudiante';
    
    await createNotificationAndSendPush(
      solicitud.tutorId, // Notificar al TUTOR
      'Nueva solicitud de tutoría',
      `${nombreEstudiante} solicita una tutoría de ${solicitud.curso}`,
      'solicitudTutoria',
      {
        solicitudId: context.params.solicitudId,
        estudianteId: solicitud.estudianteId,
        materia: solicitud.curso,
      }
    );
  });

// Trigger cuando un tutor acepta/rechaza una solicitud
export const onSolicitudTutoriaUpdated = functions.firestore
  .document('solicitudes_tutoria/{solicitudId}')
  .onUpdate(async (change, context) => {
    const solicitudAnterior = change.before.data();
    const solicitudNueva = change.after.data();

    // Salir si el estado no cambió, o si el estado es 'aceptada'
    // El caso de 'aceptada' se maneja en 'onSesionTutoriaCreated'
    if (
      solicitudAnterior.estado === solicitudNueva.estado ||
      solicitudNueva.estado === 'aceptada'
    ) {
      return null;
    }

    // A este punto, solo procesamos el rechazo
    const tutorDoc = await db.collection('tutores').doc(solicitudNueva.tutorId).get();
    const tutorData = tutorDoc.data();
    const nombreTutor = tutorData
      ? `${tutorData.nombre} ${tutorData.apellidos}`.trim()
      : 'Tutor';

    await createNotificationAndSendPush(
      solicitudNueva.estudianteId, // Notificar al ESTUDIANTE
      'Solicitud rechazada',
      `${nombreTutor} rechazó tu solicitud de tutoría de ${solicitudNueva.curso}`,
      'respuestaSolicitud',
      {
        solicitudId: context.params.solicitudId,
        tutorId: solicitudNueva.tutorId,
        materia: solicitudNueva.curso,
        aceptada: 'false',
      }
    );
    return null;
  });

// Trigger cuando una solicitud aceptada crea una nueva sesión
export const onSesionTutoriaCreated = functions.firestore
  .document('sesiones_tutoria/{sesionId}')
  .onCreate(async (snap, context) => {
    const sesion = snap.data();
    const tutorDoc = await db.collection('tutores').doc(sesion.tutorId).get();
    const tutorData = tutorDoc.data();
    const nombreTutor = tutorData
      ? `${tutorData.nombre} ${tutorData.apellidos}`.trim()
      : 'Tutor';

    await createNotificationAndSendPush(
      sesion.estudianteId, // Notificar al ESTUDIANTE
      'Sesión de tutoría confirmada',
      `Tu sesión de ${sesion.curso} con ${nombreTutor} ha sido confirmada.`,
      'sesionConfirmada',
      {
        sesionId: context.params.sesionId,
        tutorId: sesion.tutorId,
        materia: sesion.curso,
      }
    );
  });

// Función HTTP para enviar notificaciones manuales (ej. desde panel admin)
export const sendNotification = functions.https.onCall(async (data, context) => {
  if (!context.auth) {
    throw new functions.https.HttpsError('unauthenticated', 'Usuario no autenticado');
  }

  const { userId, title, body, notificationData } = data;
  const userDoc = await db.collection('users').doc(context.auth.uid).get();
  const userRole = userDoc.data()?.role;

  if (userRole !== 'admin' && userRole !== 'superAdmin') {
    throw new functions.https.HttpsError('permission-denied', 'Sin permisos');
  }

  await createNotificationAndSendPush(userId, title, body, 'manual', notificationData);
  return { success: true };
});

// Función programada para enviar recordatorios de sesiones
export const sendSessionReminders = functions.pubsub
  .schedule('every 1 hours')
  .onRun(async (context) => {
    const now = new Date();
    const thirtyMinutesFromNow = new Date(now.getTime() + 30 * 60 * 1000);

    const sesionesSnapshot = await db.collection('sesiones_tutoria')
      .where('fechaSesion', '>=', now)
      .where('fechaSesion', '<=', thirtyMinutesFromNow)
      .where('estado', '==', 'aceptada')
      .get();

    for (const doc of sesionesSnapshot.docs) {
      const sesion = doc.data();
      const tutorDoc = await db.collection('tutores').doc(sesion.tutorId).get();
      const nombreTutor = tutorDoc.data()
        ? `${tutorDoc.data()!.nombre} ${tutorDoc.data()!.apellidos}`.trim()
        : 'Tutor';

      await createNotificationAndSendPush(
        sesion.estudianteId,
        'Recordatorio de sesión',
        `Tienes una sesión de ${sesion.curso} con ${nombreTutor} en 30 minutos.`,
        'recordatorioSesion',
        {
          sesionId: doc.id,
          tutorId: sesion.tutorId,
          materia: sesion.curso,
        }
      );
    }
    console.log(`Enviados ${sesionesSnapshot.docs.length} recordatorios de sesión.`);
    return null;
  }); 