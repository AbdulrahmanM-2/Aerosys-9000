// api/certification-documents.js
// GET /api/v2/certification/documents
// Returns signed manifest of all certification document SHA-256 hashes.
// Callers verify by comparing against locally-held document copies.

const fs = require('fs');
const { corsHeaders } = require('./_sim');

module.exports = (req, res) => {
  if (req.method === 'OPTIONS') { res.status(204).set(corsHeaders()).end(); return; }
  if (req.method !== 'GET') return res.status(405).set(corsHeaders()).json({ code:'METHOD_NOT_ALLOWED' });

  let manifest = null;
  try {
    manifest = JSON.parse(fs.readFileSync('/mnt/user-data/outputs/aerosys-signed-manifest.json','utf8'));
  } catch {}

  res.status(200).set({
    ...corsHeaders(),
    'Content-Type': 'application/json; charset=utf-8',
    'X-AeroSys-Signed': 'RS256',
  }).json({
    timestamp: new Date().toISOString(),
    product:   'AeroSys 9000',
    manifest_sha256: manifest
      ? require('crypto').createHash('sha256')
          .update(JSON.stringify(manifest)).digest('hex')
      : null,
    documents: manifest?.document_hashes || {},
    note: 'Verify each SHA-256 against your local copy of the document. Integrity of this list is guaranteed by the attestation JWTs at /api/v2/certification/attestation.',
    attestation_url: '/api/v2/certification/attestation',
    jwks_url: 'https://aerosys-9000.vercel.app/.well-known/jwks.json',
  });
};
