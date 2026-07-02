const BASE_URL = '/api/cruce';

export async function uploadCsv(file, onProgress) {
    const formData = new FormData();
    formData.append('file', file);

    const response = await fetch(`${BASE_URL}/upload`, {
        method: 'POST',
        body: formData,
        headers: {
            'Accept': 'application/json',
        },
    });

    if (!response.ok) {
        const err = await response.json().catch(() => ({ error: 'Error de conexión' }));
        throw new Error(err.error || `Error HTTP ${response.status}`);
    }

    return response.json();
}

export async function getLotes(page = 1, q = '') {
    const params = new URLSearchParams({ per_page: 50, page });
    if (q) params.set('q', q);
    const res = await fetch(`${BASE_URL}/lotes?${params}`);
    return res.json();
}

export async function getLoteStatus(loteId) {
    const res = await fetch(`${BASE_URL}/lotes/${loteId}/status`);
    return res.json();
}

export async function getPendientes(loteId, page = 1, q = '') {
    const params = new URLSearchParams({ per_page: 50, page });
    if (q) params.set('q', q);
    const res = await fetch(`${BASE_URL}/lotes/${loteId}/pendientes?${params}`);
    return res.json();
}

export async function getCandidatos(ingresanteId) {
    const res = await fetch(`${BASE_URL}/ingresantes/${ingresanteId}/candidatos`);
    return res.json();
}

export async function confirmarMatch(ingresanteId, alumnoId) {
    const res = await fetch(`${BASE_URL}/ingresantes/${ingresanteId}/confirmar`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json', 'Accept': 'application/json' },
        body: JSON.stringify({ alumno_id: alumnoId }),
    });
    return res.json();
}
