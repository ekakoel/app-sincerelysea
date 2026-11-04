const { onCall, HttpsError } = require('firebase-functions/v2/https');
const { initializeApp } = require('firebase-admin/app');
const { getFirestore, FieldValue } = require('firebase-admin/firestore');
const { getAuth } = require('firebase-admin/auth');

initializeApp();

// Server catalog. Client prices are ignored.
// Replace this constant with admin-written Firestore products before production.
const CATALOG = {
  'jane-medium': { name: 'Jane Medium', priceIdr: 1500000 },
  'jane-sand': { name: 'Jane · Sand', priceIdr: 1500000 },
  'viola-sling': { name: 'Viola Sling', priceIdr: 830000 },
  satchel: { name: 'Satchel', priceIdr: 1750000 },
};

function quoteLines(lines) {
  if (!Array.isArray(lines) || lines.length === 0) {
    throw new HttpsError('failed-precondition', 'Cart is empty.');
  }
  let subtotalIdr = 0;
  const quoted = lines.map((line) => {
    const product = CATALOG[line.productId];
    const quantity = Number(line.quantity);
    if (!product) {
      throw new HttpsError('invalid-argument', 'Unknown product.');
    }
    if (!Number.isInteger(quantity) || quantity < 1 || quantity > 5) {
      throw new HttpsError('invalid-argument', 'Quantity must be between 1 and 5.');
    }
    subtotalIdr += product.priceIdr * quantity;
    return {
      productId: line.productId,
      name: product.name,
      quantity,
      unitPriceIdr: product.priceIdr,
    };
  });
  return { lines: quoted, subtotalIdr };
}

exports.quoteCart = onCall((request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in to continue.');
  }
  return quoteLines(request.data?.lines);
});

exports.createOrder = onCall(async (request) => {
  if (!request.auth) {
    throw new HttpsError('unauthenticated', 'Sign in to continue.');
  }
  const quote = quoteLines(request.data?.lines);
  const shipTo = String(request.data?.shipTo || '').trim();
  if (shipTo.length < 3) {
    throw new HttpsError('invalid-argument', 'Add a shipping address.');
  }
  const ref = getFirestore().collection('orders').doc();
  await ref.set({
    userId: request.auth.uid,
    lines: quote.lines,
    subtotalIdr: quote.subtotalIdr,
    status: 'awaiting_payment',
    shipTo,
    createdAt: FieldValue.serverTimestamp(),
  });
  await getFirestore().collection('audit_log').add({
    action: 'create-order',
    orderId: ref.id,
    actorId: request.auth.uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { orderId: ref.id, status: 'awaiting_payment', subtotalIdr: quote.subtotalIdr };
});

exports.setUserAdminAccess = onCall(async (request) => {
  if (!request.auth || request.auth.token.admin !== true) {
    throw new HttpsError('permission-denied', 'Administrator claim required.');
  }
  const uid = String(request.data?.uid || '');
  const admin = request.data?.admin === true;
  if (!uid) {
    throw new HttpsError('invalid-argument', 'uid is required.');
  }
  const user = await getAuth().getUser(uid);
  const claims = { ...(user.customClaims || {}), admin };
  await getAuth().setCustomUserClaims(uid, claims);
  await getFirestore().collection('audit_log').add({
    action: admin ? 'grant-admin' : 'revoke-admin',
    targetUid: uid,
    actorId: request.auth.uid,
    createdAt: FieldValue.serverTimestamp(),
  });
  return { uid, admin };
});

// Payment providers must call a signed HTTPS endpoint, not the mobile client.
exports.confirmPayment = onCall(() => {
  throw new HttpsError(
    'failed-precondition',
    'Payment status is confirmed only by a verified provider callback.',
  );
});
