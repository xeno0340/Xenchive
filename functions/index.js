/**
 * XENCHIVE — Smart Classroom & Timetable Scheduler (CSRA)
 * Cloud Functions (callable):
 *  - timetableByPersonnel (FR 1.1 / FR 1.3)
 *  - getChartData         (FR 2.1 / FR 2.2)
 *  - emailDraftFromTemplate (FR 3.1 – FR 3.4)
 */

const functions = require("firebase-functions");
const admin = require("firebase-admin");
admin.initializeApp();

const db = admin.firestore();
const log = functions.logger;

/* ----------------------------- helpers ----------------------------- */

const norm = (s) => (typeof s === "string" ? s.trim() : "");
const timeStr = (t) => {
  // Accept "10:00" / "11:00" strings OR Firestore Timestamps / Dates
  if (!t) return "";
  if (typeof t === "string") return t;
  if (t.toDate) {
    const d = t.toDate();
    const hh = String(d.getHours()).padStart(2, "0");
    const mm = String(d.getMinutes()).padStart(2, "0");
    return `${hh}:${mm}`;
  }
  if (t instanceof Date) {
    const hh = String(t.getHours()).padStart(2, "0");
    const mm = String(t.getMinutes()).padStart(2, "0");
    return `${hh}:${mm}`;
  }
  return String(t);
};

const idFromRefOrString = (v) => {
  // Accept "p1" / "r1" OR DocumentReference
  if (!v) return "";
  if (typeof v === "string") return v;
  if (v.id) return v.id; // DocumentReference
  return "";
};

const safeRoomName = (roomDoc) => {
  if (!roomDoc || !roomDoc.exists) return "";
  const r = roomDoc.data() || {};
  return r.name || r.roomName || ""; // tolerate either field
};

/* -------------------- FR 1.1 / FR 1.3 timetable -------------------- */
/**
 * Request shape:
 *   { personName: "Dr. Smith", dayOfWeek: "Tuesday" }
 */
exports.timetableByPersonnel = functions.https.onCall(async (data) => {
  const personName = norm(data.personName);
  const dayOfWeek = norm(data.dayOfWeek);

  log.info("timetableByPersonnel:req", { personName, dayOfWeek });

  const empty = {
    kind: "timetable_list",
    columns: ["Day", "Time", "Course", "Faculty", "Room"],
    rows: [],
  };
  if (!personName) return empty;

  // Find faculty by exact name (case-sensitive).
  // If not found, try a prefix match as a fallback (needs 'name' sorted).
  let peopleSnap = await db
    .collection("people")
    .where("name", "==", personName)
    .limit(1)
    .get();

  if (peopleSnap.empty) {
    // fallback: prefix search (optional)
    peopleSnap = await db
      .collection("people")
      .where("name", ">=", personName)
      .where("name", "<=", personName + "\uf8ff")
      .limit(1)
      .get();
  }

  log.info("timetableByPersonnel:peopleSnap.size", peopleSnap.size);
  if (peopleSnap.empty) return empty;

  const facultyId = peopleSnap.docs[0].id;
  log.info("timetableByPersonnel:facultyId", facultyId);

  // Query classes for this faculty (facultyId is stored as *string id* per your screenshots)
  let q = db.collection("classes").where("facultyId", "==", facultyId);
  if (dayOfWeek) q = q.where("dayOfWeek", "==", dayOfWeek);
  const classesSnap = await q.get();
  log.info("timetableByPersonnel:classesSnap.size", classesSnap.size);

  if (classesSnap.empty) return empty;

  const rows = await Promise.all(
    classesSnap.docs.map(async (d) => {
      const c = d.data() || {};
      log.debug("timetableByPersonnel:classDoc", { id: d.id, ...c });

      const roomId = idFromRefOrString(c.roomId);
      const roomDoc = roomId ? await db.collection("rooms").doc(roomId).get() : null;

      const start = timeStr(c.startTime);
      const end = timeStr(c.endTime);

      return [
        c.dayOfWeek || "",
        end ? `${start}–${end}` : start,
        c.courseName || "",
        personName,
        safeRoomName(roomDoc),
      ];
    })
  );

  return {
    kind: "timetable_list",
    columns: ["Day", "Time", "Course", "Faculty", "Room"],
    rows,
  };
});

/* --------------------- FR 2.1 / FR 2.2 charts ---------------------- */
/**
 * Request shape:
 *   { metric: "Room Utilization (%)", groupBy: "dayOfWeek", type: "bar" }
 */
exports.getChartData = functions.https.onCall(async (data) => {
  const metric = norm(data.metric) || "Room Utilization (%)";
  const groupBy = norm(data.groupBy) || "dayOfWeek";
  const type = norm(data.type) || "bar";

  const days = ["Monday", "Tuesday", "Wednesday", "Thursday", "Friday"];
  const counts = Object.fromEntries(days.map((d) => [d, 0]));

  const snap = await db.collection("classes").get();
  snap.forEach((doc) => {
    const c = doc.data() || {};
    const d = c[groupBy];
    if (d && counts[d] != null) counts[d] += 1;
  });

  return {
    kind: "chart",
    metric,
    type,
    groupBy,
    labels: days,
    values: days.map((d) => counts[d]),
  };
});

/* ------------------- FR 3.1 – FR 3.4 email draft ------------------- */
/**
 * Request shape:
 *   {
 *     courseName: "Physics 101",
 *     template: "Timetable Update",
 *     vars: {
 *       newTime: "11:00",
 *       newRoom: "B-204",
 *       audience: "Students",
 *       senderName: "Admin",
 *       date: "2025-11-08",
 *       oldTime: "10:00",
 *       oldRoom: "B-204"
 *     }
 *   }
 */
exports.emailDraftFromTemplate = functions.https.onCall(async (data) => {
  const courseName = norm(data.courseName);
  const templateName = norm(data.template) || "Timetable Update";
  const vars = data.vars || {};

  log.info("emailDraft:req", { courseName, templateName, vars });

  // Fetch template by name, fall back to defaults
  const tSnap = await db
    .collection("emailTemplates")
    .where("name", "==", templateName)
    .limit(1)
    .get();

  const tpl = tSnap.empty
    ? {
        subjectTemplate: "{{courseName}} – Timetable Update ({{date}})",
        bodyTemplate:
          "Dear {{audience}}, {{courseName}} at {{oldTime}} in {{oldRoom}} is moved to {{newTime}} in {{newRoom}}.\n– {{senderName}}",
      }
    : tSnap.docs[0].data();

  // Try to resolve course → faculty → email
  let to = [];
  if (courseName) {
    const cSnap = await db
      .collection("classes")
      .where("courseName", "==", courseName)
      .limit(1)
      .get();

    if (!cSnap.empty) {
      const c = cSnap.docs[0].data() || {};
      const facultyId = idFromRefOrString(c.facultyId);
      if (facultyId) {
        const fDoc = await db.collection("people").doc(facultyId).get();
        if (fDoc.exists) {
          const f = fDoc.data() || {};
          if (f.email) to = [f.email];
        }
      }
    }
  }

  const fill = (text) =>
    (text || "")
      .replaceAll("{{courseName}}", vars.courseName || courseName || "")
      .replaceAll("{{oldTime}}", timeStr(vars.oldTime))
      .replaceAll("{{newTime}}", timeStr(vars.newTime))
      .replaceAll("{{oldRoom}}", vars.oldRoom || "")
      .replaceAll("{{newRoom}}", vars.newRoom || "")
      .replaceAll("{{date}}", norm(vars.date))
      .replaceAll("{{audience}}", vars.audience || "Students")
      .replaceAll("{{senderName}}", vars.senderName || "Scheduler Bot");

  const subject = fill(tpl.subjectTemplate);
  const body = fill(tpl.bodyTemplate);

  return {
    kind: "email_draft",
    to, // faculty email (can be empty if not resolvable)
    subject,
    body,
    requiresConfirmation: true, // FR 3.4 – caller should show confirmation dialog before send
  };
});
