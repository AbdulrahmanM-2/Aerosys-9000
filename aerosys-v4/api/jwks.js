// api/jwks.js — GET /.well-known/jwks.json (RFC 7517)
// Public key endpoint — NO AUTH. Publicly accessible for signature verification.
const crypto = require('crypto');

// Public key embedded as env var at deploy time. Private key NEVER deployed.
const PUBLIC_KEY_PEM = process.env.AEROSYS_PUBLIC_KEY || null;

module.exports = (req, res) => {
  if (!PUBLIC_KEY_PEM) {
    return res.status(503).json({
      error: 'PUBLIC_KEY_NOT_CONFIGURED',
      message: 'Set AEROSYS_PUBLIC_KEY environment variable in Vercel dashboard'
    });
  }

  const pubKeyObj = crypto.createPublicKey(PUBLIC_KEY_PEM);
  const jwk = pubKeyObj.export({ format: 'jwk' });
  const kid = crypto.createHash('sha256').update(PUBLIC_KEY_PEM).digest('base64url').slice(0,43);

  res.status(200).set({
    'Content-Type': 'application/json',
    'Access-Control-Allow-Origin': '*',
    'Cache-Control': 'public, max-age=3600',
  }).json({
    keys: [{
      kty: jwk.kty, use: 'sig', alg: 'RS256', kid,
      n: jwk.n, e: jwk.e,
      'x-cert-issuer':   'aerosys-9000.certification.aero',
      'x-cert-project':  'AeroSys 9000 v1.0.0',
      'x-cert-standard': 'DO-178C RTCA / EUROCAE ED-12C',
      'x-key-bits':      4096,
    }],
    verify_endpoint: 'https://aerosys-9000.vercel.app/api/v2/verify',
    sign_endpoint:   'https://aerosys-9000.vercel.app/api/v2/sign',
  });
};
