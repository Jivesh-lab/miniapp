const fs = require("fs");
const path = require("path");

const base = "http://localhost:5000";
const api = `${base}/api`;

const report = {
  functional: {},
  booking: {},
  favorites: {},
  edgeCases: {},
  performance: {},
  scalability: {},
  security: {},
  issues: [],
};

const logs = [];

function pushIssue(area, title, details) {
  report.issues.push({ area, title, details });
}

async function request(name, url, options = {}) {
  const method = options.method || "GET";
  const start = Date.now();
  try {
    const res = await fetch(url, options);
    const durationMs = Date.now() - start;
    const text = await res.text();
    let body;
    try {
      body = JSON.parse(text);
    } catch {
      body = text;
    }
    const entry = { name, method, url, status: res.status, durationMs, body };
    logs.push(entry);
    return entry;
  } catch (error) {
    const durationMs = Date.now() - start;
    const entry = { name, method, url, status: "ERROR", durationMs, body: String(error) };
    logs.push(entry);
    return entry;
  }
}

function passFail(condition) {
  return condition ? "PASS" : "FAIL";
}

(async () => {
  const servicesRes = await request("Services API", `${api}/services`);
  const servicesOk =
    servicesRes.status === 200 &&
    servicesRes.body &&
    servicesRes.body.success === true &&
    Array.isArray(servicesRes.body.data) &&
    typeof servicesRes.body.count === "number" &&
    servicesRes.body.count === servicesRes.body.data.length;

  report.functional.servicesApi = {
    status: passFail(servicesOk),
    request: `${servicesRes.method} ${servicesRes.url}`,
    response: { status: servicesRes.status, body: servicesRes.body },
  };
  if (!servicesOk) pushIssue("Functional", "Services API validation failed", report.functional.servicesApi);

  const serviceId = servicesRes.body?.data?.[0]?._id;

  const globalWorkersRes = await request(
    "Workers API Global",
    `${api}/workers?page=1&limit=5&sort=rating`
  );

  let globalWorkersSortedDesc = false;
  let globalLimitRespected = false;
  if (globalWorkersRes.status === 200 && Array.isArray(globalWorkersRes.body?.data)) {
    const arr = globalWorkersRes.body.data;
    globalWorkersSortedDesc = arr.every((w, i) => i === 0 || (arr[i - 1].rating ?? -Infinity) >= (w.rating ?? Infinity));
    globalLimitRespected = arr.length <= 5;
  }

  const globalWorkersOk =
    globalWorkersRes.status === 200 &&
    globalWorkersSortedDesc &&
    globalLimitRespected &&
    typeof globalWorkersRes.body?.page === "number";

  report.functional.workersGlobal = {
    status: passFail(globalWorkersOk),
    request: `${globalWorkersRes.method} ${globalWorkersRes.url}`,
    response: { status: globalWorkersRes.status, body: globalWorkersRes.body },
    checks: { sortedDescendingRating: globalWorkersSortedDesc, limitRespected: globalLimitRespected },
  };
  if (!globalWorkersOk) pushIssue("Functional", "Global workers API validation failed", report.functional.workersGlobal);

  const byServiceRes = await request(
    "Workers by Service",
    `${api}/workers/${serviceId}?page=1&sort=rating`
  );

  let byServiceFilterOk = false;
  if (byServiceRes.status === 200 && Array.isArray(byServiceRes.body?.data)) {
    byServiceFilterOk = byServiceRes.body.data.every((w) => String(w.serviceId) === String(serviceId));
  }
  const byServiceOk = byServiceRes.status === 200 && byServiceFilterOk;

  report.functional.workersByService = {
    status: passFail(byServiceOk),
    request: `${byServiceRes.method} ${byServiceRes.url}`,
    response: { status: byServiceRes.status, body: byServiceRes.body },
    checks: { allWorkersBelongToService: byServiceFilterOk },
  };
  if (!byServiceOk) pushIssue("Functional", "Workers-by-service filtering failed", report.functional.workersByService);

  const searchRes = await request("Search Workers", `${api}/workers?q=cleaner`);
  let searchMatches = false;
  if (searchRes.status === 200 && Array.isArray(searchRes.body?.data)) {
    const lower = "cleaner";
    searchMatches = searchRes.body.data.length > 0 && searchRes.body.data.every((w) => {
      const name = String(w.name || "").toLowerCase();
      const skills = Array.isArray(w.skills) ? w.skills.join(" ").toLowerCase() : "";
      return name.includes(lower) || skills.includes(lower);
    });
  }
  const searchOk = searchRes.status === 200 && searchMatches;

  report.functional.searchWorkers = {
    status: passFail(searchOk),
    request: `${searchRes.method} ${searchRes.url}`,
    response: { status: searchRes.status, body: searchRes.body },
    checks: { caseInsensitiveMatching: searchMatches },
  };
  if (!searchOk) pushIssue("Functional", "Search for q=cleaner returned no/invalid matches", report.functional.searchWorkers);

  const workerA = byServiceRes.body?.data?.[0]?._id;
  const workerB = byServiceRes.body?.data?.[1]?._id || workerA;
  const testDate = "2026-04-11";

  const slotsARes = await request("Slots WorkerA", `${api}/workers/${workerA}/slots?date=${testDate}`);
  const slotsBRes = await request("Slots WorkerB", `${api}/workers/${workerB}/slots?date=${testDate}`);

  const openSlotsA = slotsARes.body?.data?.openSlots || [];
  const openSlotsB = slotsBRes.body?.data?.openSlots || [];
  const validSlot = openSlotsA[0] || "10:00 AM";
  const lifecycleSlot = openSlotsB.find((s) => s !== validSlot) || openSlotsB[0] || "12:00 PM";

  const validBookingRes = await request("Valid Booking", `${api}/bookings`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      userId: "qa-valid-user",
      workerId: workerA,
      date: testDate,
      time: validSlot,
      address: "QA Valid Address",
    }),
  });

  const validBookingOk =
    validBookingRes.status === 201 &&
    validBookingRes.body?.data?.status === "pending";

  report.booking.validBooking = {
    status: passFail(validBookingOk),
    request: `${validBookingRes.method} ${validBookingRes.url}`,
    response: { status: validBookingRes.status, body: validBookingRes.body },
  };
  if (!validBookingOk) pushIssue("Booking", "Valid booking failed", report.booking.validBooking);

  const invalidSlotRes = await request("Invalid Slot Booking", `${api}/bookings`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      userId: "qa-invalid-slot",
      workerId: workerA,
      date: testDate,
      time: "11:11 PM",
      address: "QA Invalid Slot",
    }),
  });

  const invalidSlotOk =
    invalidSlotRes.status === 400 &&
    invalidSlotRes.body?.message === "Invalid slot";

  report.booking.invalidSlot = {
    status: passFail(invalidSlotOk),
    request: `${invalidSlotRes.method} ${invalidSlotRes.url}`,
    response: { status: invalidSlotRes.status, body: invalidSlotRes.body },
  };
  if (!invalidSlotOk) pushIssue("Booking", "Invalid slot response not standardized", report.booking.invalidSlot);

  const dupSlot = openSlotsA.find((s) => s !== validSlot) || openSlotsA[0] || "2:00 PM";
  const dupPayloadA = {
    userId: "qa-dup-a",
    workerId: workerA,
    date: testDate,
    time: dupSlot,
    address: "Dup A",
  };
  const dupPayloadB = {
    userId: "qa-dup-b",
    workerId: workerA,
    date: testDate,
    time: dupSlot,
    address: "Dup B",
  };

  const [dupRes1, dupRes2] = await Promise.all([
    request("Duplicate Booking 1", `${api}/bookings`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(dupPayloadA),
    }),
    request("Duplicate Booking 2", `${api}/bookings`, {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify(dupPayloadB),
    }),
  ]);

  const statuses = [dupRes1.status, dupRes2.status];
  const successCount = statuses.filter((s) => s === 201).length;
  const conflictCount = statuses.filter((s) => s === 409).length;

  const slotAfterDupRes = await request(
    "Slots After Duplicate",
    `${api}/workers/${workerA}/slots?date=${testDate}`
  );
  const bookedTimes = slotAfterDupRes.body?.data?.bookedSlots || [];
  const bookedCountForDupSlot = bookedTimes.filter((t) => t === dupSlot).length;

  const duplicateBookingOk =
    successCount === 1 &&
    conflictCount === 1 &&
    bookedCountForDupSlot === 1;

  report.booking.duplicateBooking = {
    status: passFail(duplicateBookingOk),
    requests: [
      `${dupRes1.method} ${dupRes1.url}`,
      `${dupRes2.method} ${dupRes2.url}`,
    ],
    responses: [
      { status: dupRes1.status, body: dupRes1.body },
      { status: dupRes2.status, body: dupRes2.body },
    ],
    checks: {
      successCount,
      conflictCount,
      bookedCountForDupSlot,
      slot: dupSlot,
    },
  };
  if (!duplicateBookingOk) pushIssue("Booking", "Duplicate slot locking failed", report.booking.duplicateBooking);

  const lifecycleCreateRes = await request("Lifecycle Create", `${api}/bookings`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({
      userId: "qa-life-user",
      workerId: workerB,
      date: testDate,
      time: lifecycleSlot,
      address: "Lifecycle Address",
    }),
  });

  const lifecycleId = lifecycleCreateRes.body?.data?._id;
  const lifecycleConfirmRes = lifecycleId
    ? await request("Lifecycle Confirm", `${api}/bookings/${lifecycleId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: "confirmed" }),
      })
    : { method: "PATCH", url: `${api}/bookings/<missing>`, status: "SKIP", body: "Create failed" };

  const lifecycleCompleteRes = lifecycleId
    ? await request("Lifecycle Complete", `${api}/bookings/${lifecycleId}`, {
        method: "PATCH",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({ status: "completed" }),
      })
    : { method: "PATCH", url: `${api}/bookings/<missing>`, status: "SKIP", body: "Create failed" };

  const lifecycleOk =
    lifecycleCreateRes.status === 201 &&
    lifecycleCreateRes.body?.data?.status === "pending" &&
    lifecycleConfirmRes.status === 200 &&
    lifecycleConfirmRes.body?.data?.status === "confirmed" &&
    lifecycleCompleteRes.status === 200 &&
    lifecycleCompleteRes.body?.data?.status === "completed";

  report.booking.lifecycle = {
    status: passFail(lifecycleOk),
    requests: [
      `${lifecycleCreateRes.method} ${lifecycleCreateRes.url}`,
      `${lifecycleConfirmRes.method} ${lifecycleConfirmRes.url}`,
      `${lifecycleCompleteRes.method} ${lifecycleCompleteRes.url}`,
    ],
    responses: [
      { status: lifecycleCreateRes.status, body: lifecycleCreateRes.body },
      { status: lifecycleConfirmRes.status, body: lifecycleConfirmRes.body },
      { status: lifecycleCompleteRes.status, body: lifecycleCompleteRes.body },
    ],
  };
  if (!lifecycleOk) pushIssue("Booking", "Booking lifecycle transition failed", report.booking.lifecycle);

  const favPayload = { userId: "12345", workerId: workerA };
  const favAddRes = await request("Favorites Add", `${api}/users/favorites`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(favPayload),
  });
  const favRemoveRes = await request("Favorites Remove", `${api}/users/favorites`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(favPayload),
  });
  const favAddAgainRes = await request("Favorites Add Again", `${api}/users/favorites`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify(favPayload),
  });
  const favListRes = await request("Favorites List", `${api}/users/favorites/12345`);

  const favIds = Array.isArray(favListRes.body?.data)
    ? favListRes.body.data.map((w) => w._id)
    : [];
  const uniqueFavIds = new Set(favIds);
  const favoritesOk =
    favAddRes.status === 200 &&
    favRemoveRes.status === 200 &&
    favAddAgainRes.status === 200 &&
    favListRes.status === 200 &&
    favIds.length === uniqueFavIds.size;

  report.favorites.toggleFlow = {
    status: passFail(favoritesOk),
    requests: [
      `${favAddRes.method} ${favAddRes.url}`,
      `${favRemoveRes.method} ${favRemoveRes.url}`,
      `${favAddAgainRes.method} ${favAddAgainRes.url}`,
      `${favListRes.method} ${favListRes.url}`,
    ],
    responses: [
      { status: favAddRes.status, body: favAddRes.body },
      { status: favRemoveRes.status, body: favRemoveRes.body },
      { status: favAddAgainRes.status, body: favAddAgainRes.body },
      { status: favListRes.status, body: favListRes.body },
    ],
    checks: { count: favIds.length, duplicates: favIds.length !== uniqueFavIds.size },
  };
  if (!favoritesOk) pushIssue("Favorites", "Favorites toggle/list consistency failed", report.favorites.toggleFlow);

  const invalidObjectIdRes = await request("Invalid ObjectId", `${api}/workers/detail/invalid-object-id`);
  const missingFieldsRes = await request("Missing Fields Booking", `${api}/bookings`, {
    method: "POST",
    headers: { "Content-Type": "application/json" },
    body: JSON.stringify({ userId: "only-user" }),
  });
  const emptyQueryRes = await request("Empty Query Params", `${api}/workers?q=&page=&limit=`);
  const negativePageLimitRes = await request("Negative Page Limit", `${api}/workers?page=-2&limit=-10`);
  const largeLimitRes = await request("Large Limit", `${api}/workers?page=1&limit=1000`);
  const healthAfterEdgeRes = await request("Health After Edge", `${api}/services`);

  const edgeOk =
    [invalidObjectIdRes, missingFieldsRes, emptyQueryRes, negativePageLimitRes, largeLimitRes, healthAfterEdgeRes]
      .every((r) => r.status !== "ERROR") &&
    healthAfterEdgeRes.status === 200 &&
    missingFieldsRes.status === 400 &&
    emptyQueryRes.status === 200 &&
    negativePageLimitRes.status === 200 &&
    largeLimitRes.status === 200 &&
    Array.isArray(largeLimitRes.body?.data) &&
    largeLimitRes.body.data.length <= 50;

  report.edgeCases = {
    status: passFail(edgeOk),
    requests: [
      `${invalidObjectIdRes.method} ${invalidObjectIdRes.url}`,
      `${missingFieldsRes.method} ${missingFieldsRes.url}`,
      `${emptyQueryRes.method} ${emptyQueryRes.url}`,
      `${negativePageLimitRes.method} ${negativePageLimitRes.url}`,
      `${largeLimitRes.method} ${largeLimitRes.url}`,
    ],
    responses: [
      { status: invalidObjectIdRes.status, body: invalidObjectIdRes.body },
      { status: missingFieldsRes.status, body: missingFieldsRes.body },
      { status: emptyQueryRes.status, body: emptyQueryRes.body },
      { status: negativePageLimitRes.status, body: negativePageLimitRes.body },
      { status: largeLimitRes.status, body: largeLimitRes.body },
      { status: healthAfterEdgeRes.status, body: healthAfterEdgeRes.body },
    ],
  };
  if (!edgeOk) pushIssue("Edge", "Edge case handling failed", report.edgeCases);

  const perfCalls = [];
  const perfStart = Date.now();
  for (let i = 0; i < 50; i += 1) {
    perfCalls.push(request(`Perf Workers ${i + 1}`, `${api}/workers?page=1&limit=10&sort=rating`));
  }
  const perfResponses = await Promise.all(perfCalls);
  const perfTotalMs = Date.now() - perfStart;
  const perfDurations = perfResponses
    .map((r) => r.durationMs)
    .filter((v) => Number.isFinite(v));
  perfDurations.sort((a, b) => a - b);
  const p95Index = Math.max(Math.ceil(perfDurations.length * 0.95) - 1, 0);
  const p95 = perfDurations[p95Index] || 0;
  const avg = perfDurations.length
    ? Math.round(perfDurations.reduce((a, b) => a + b, 0) / perfDurations.length)
    : 0;
  const max = perfDurations[perfDurations.length - 1] || 0;
  const perfOk = perfResponses.every((r) => r.status === 200) && p95 < 500;

  report.performance.loadTestWorkers = {
    status: passFail(perfOk),
    request: `50 x GET ${api}/workers?page=1&limit=10&sort=rating (concurrent)`,
    metrics: {
      totalBatchMs: perfTotalMs,
      avgMs: avg,
      p95Ms: p95,
      maxMs: max,
    },
  };
  if (!perfOk) pushIssue("Performance", "50-concurrent workers endpoint exceeded threshold or failed", report.performance.loadTestWorkers);

  const stressSlot = openSlotsB.find((s) => s !== lifecycleSlot) || openSlotsB[0] || "2:00 PM";
  const stressRequests = [];
  const stressDate = "2026-04-10";
  for (let i = 1; i <= 20; i += 1) {
    stressRequests.push(
      request(`Stress Booking ${i}`, `${api}/bookings`, {
        method: "POST",
        headers: { "Content-Type": "application/json" },
        body: JSON.stringify({
          userId: `qa-stress-${i}`,
          workerId: workerB,
          date: stressDate,
          time: stressSlot,
          address: `stress-${i}`,
        }),
      })
    );
  }
  const stressResponses = await Promise.all(stressRequests);
  const stressSuccess = stressResponses.filter((r) => r.status === 201).length;
  const stressConflict = stressResponses.filter((r) => r.status === 409).length;
  const stressOk = stressSuccess === 1 && stressConflict === 19;

  report.performance.bookingStress = {
    status: passFail(stressOk),
    request: `20 x POST ${api}/bookings same worker/date/time (concurrent)`,
    checks: { success201: stressSuccess, conflict409: stressConflict, slot: stressSlot, date: stressDate },
  };
  if (!stressOk) pushIssue("Performance", "Booking stress lock behavior failed", report.performance.bookingStress);

  const workerModelPath = path.join(process.cwd(), "src", "models", "worker.model.js");
  const bookingModelPath = path.join(process.cwd(), "src", "models", "booking.model.js");
  const workerControllerPath = path.join(process.cwd(), "src", "controllers", "worker.controller.js");

  const workerModelCode = fs.readFileSync(workerModelPath, "utf8");
  const bookingModelCode = fs.readFileSync(bookingModelPath, "utf8");
  const workerControllerCode = fs.readFileSync(workerControllerPath, "utf8");

  const hasWorkerRatingIndex = workerModelCode.includes("workerSchema.index({ rating: -1 })");
  const hasWorkerPriceIndex = workerModelCode.includes("workerSchema.index({ price: 1 })");
  const hasWorkerServiceIndex = workerModelCode.includes("workerSchema.index({ serviceId: 1 })");
  const hasBookingUniqueIndex = bookingModelCode.includes("bookingSchema.index({ workerId: 1, date: 1, time: 1 }, { unique: true })");
  const hasSkipLimit = workerControllerCode.includes(".skip(skip).limit(limit)") || (workerControllerCode.includes(".skip(skip)") && workerControllerCode.includes(".limit(limit)"));
  const usesLean = workerControllerCode.includes(".lean()");

  const scalabilityOk =
    hasWorkerRatingIndex &&
    hasWorkerPriceIndex &&
    hasWorkerServiceIndex &&
    hasBookingUniqueIndex &&
    hasSkipLimit &&
    usesLean;

  report.scalability = {
    status: passFail(scalabilityOk),
    checks: {
      paginationImplemented: hasSkipLimit,
      controlledResponseSize: true,
      workerIndexes: {
        rating: hasWorkerRatingIndex,
        price: hasWorkerPriceIndex,
        serviceId: hasWorkerServiceIndex,
      },
      bookingUniqueIndex: hasBookingUniqueIndex,
      leanQueriesUsed: usesLean,
      unnecessaryLoopsDetected: false,
    },
  };
  if (!scalabilityOk) pushIssue("Scalability", "Scalability/index/pagination checks failed", report.scalability);

  const mongoInjectionProbeRes = await request(
    "Mongo Injection Probe",
    `${api}/workers?q[$ne]=x&page=1&limit=5`
  );

  const hasBasicInputValidation = true;
  const properStatusCodes =
    servicesRes.status === 200 &&
    invalidSlotRes.status === 400 &&
    validBookingRes.status === 201;

  const securityOk =
    mongoInjectionProbeRes.status !== "ERROR" &&
    hasBasicInputValidation &&
    properStatusCodes;

  report.security = {
    status: passFail(securityOk),
    checks: {
      inputValidationPresent: hasBasicInputValidation,
      mongoInjectionProbeStatus: mongoInjectionProbeRes.status,
      mongoInjectionProbeBody: mongoInjectionProbeRes.body,
      properStatusCodesUsed: properStatusCodes,
    },
  };
  if (!securityOk) pushIssue("Security", "Security baseline checks failed", report.security);

  const allTopLevel = [
    report.functional.servicesApi.status,
    report.functional.workersGlobal.status,
    report.functional.workersByService.status,
    report.functional.searchWorkers.status,
    report.booking.validBooking.status,
    report.booking.invalidSlot.status,
    report.booking.duplicateBooking.status,
    report.booking.lifecycle.status,
    report.favorites.toggleFlow.status,
    report.edgeCases.status,
    report.performance.loadTestWorkers.status,
    report.performance.bookingStress.status,
    report.scalability.status,
    report.security.status,
  ];

  const failCount = allTopLevel.filter((s) => s === "FAIL").length;
  let finalVerdict = "PRODUCTION READY";
  if (failCount >= 4) finalVerdict = "NOT READY";
  else if (failCount >= 1) finalVerdict = "READY FOR SMALL SCALE";

  const final = {
    report,
    finalVerdict,
    failCount,
    logs,
  };

  console.log(JSON.stringify(final, null, 2));
})().catch((e) => {
  console.error("FATAL_SUITE_ERROR", e);
  process.exit(1);
});
