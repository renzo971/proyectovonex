import { useState, useEffect } from 'react';

function MatchStatusBadge({ estado }) {
    const styles = {
        pendiente: 'bg-yellow-100 text-yellow-800 border-yellow-200',
        confirmado_automatico: 'bg-green-100 text-green-800 border-green-200',
        confirmado_manual: 'bg-blue-100 text-blue-800 border-blue-200',
        no_ingresado: 'bg-red-100 text-red-800 border-red-200',
    };

    const labels = {
        pendiente: 'Pendiente',
        confirmado_automatico: 'Match Exacto',
        confirmado_manual: 'Match Manual',
        no_ingresado: 'No Ingresado',
    };

    return (
        <span className={`inline-flex items-center rounded-full border px-2.5 py-0.5 text-xs font-medium ${styles[estado] || styles.pendiente}`}>
            {labels[estado] || estado}
        </span>
    );
}

export default function UnmatchedRow({ ingresante, onConfirmado }) {
    const [candidates, setCandidates] = useState([]);
    const [selected, setSelected] = useState('');
    const [loading, setLoading] = useState(false);
    const [confirming, setConfirming] = useState(false);
    const [error, setError] = useState(null);

    useEffect(() => {
        if (ingresante.estado_match !== 'pendiente') return;

        let cancelled = false;

        async function load() {
            setLoading(true);
            try {
                const api = await import('../services/api.js');
                const data = await api.getCandidatos(ingresante.id);
                if (!cancelled) {
                    setCandidates(data.data?.candidates || []);
                }
            } catch {
                if (!cancelled) setError('Error al cargar candidatos');
            } finally {
                if (!cancelled) setLoading(false);
            }
        }

        load();
        return () => { cancelled = true; };
    }, [ingresante.id, ingresante.estado_match]);

    const handleConfirm = async () => {
        if (!selected && selected !== 'no_ingresado') return;

        setConfirming(true);
        setError(null);

        try {
            const api = await import('../services/api.js');
            const alumnoId = selected === 'no_ingresado' ? null : parseInt(selected, 10);
            const result = await api.confirmarMatch(ingresante.id, alumnoId);

            if (result.success) {
                if (onConfirmado) onConfirmado(ingresante.id, result.data);
            } else {
                setError(result.error || 'Error al confirmar');
            }
        } catch (err) {
            setError(err.message);
        } finally {
            setConfirming(false);
        }
    };

    if (ingresante.estado_match === 'confirmado_automatico') {
        return null;
    }

    const isResolved = ingresante.estado_match !== 'pendiente';

    return (
        <div className={`rounded-lg border p-4 ${isResolved ? 'border-gray-200 bg-gray-50' : 'border-gray-200 bg-white'}`}>
            <div className="flex items-start justify-between gap-4">
                <div className="min-w-0 flex-1">
                    <div className="flex items-center gap-2 mb-1">
                        <p className="text-sm font-medium text-gray-900">
                            {ingresante.apellido_paterno} {ingresante.apellido_materno}, {ingresante.nombres}
                        </p>
                        <MatchStatusBadge estado={ingresante.estado_match} />
                    </div>
                    <p className="text-xs text-gray-500">
                        Código: {ingresante.codigo} · EAP: {ingresante.eap} · Fecha: {ingresante.fecha}
                    </p>
                </div>

                {!isResolved && (
                    <div className="flex-shrink-0 space-y-2">
                        {loading ? (
                            <div className="flex items-center gap-2 text-sm text-gray-500">
                                <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                </svg>
                                Buscando candidatos…
                            </div>
                        ) : (
                            <>
                                <select
                                    value={selected}
                                    onChange={(e) => setSelected(e.target.value)}
                                    className="block w-full rounded-lg border border-gray-300 px-3 py-2 text-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                                >
                                    <option value="" disabled>Selecciona un alumno…</option>
                                    {candidates.map((c) => (
                                        <option key={c.alumno_id} value={c.alumno_id}>
                                            {c.nombre_completo || `ID ${c.alumno_id}`} — {c.porcentaje_similitud}%
                                        </option>
                                    ))}
                                    <option value="no_ingresado" className="text-red-600 font-medium">
                                        Sin coincidencias — Marcar como No Ingresado
                                    </option>
                                </select>

                                {error && (
                                    <p className="text-xs text-red-600">{error}</p>
                                )}

                                <button
                                    onClick={handleConfirm}
                                    disabled={!selected || confirming}
                                    className="w-full rounded-lg bg-indigo-600 px-3 py-1.5 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                                >
                                    {confirming ? 'Confirmando…' : 'Confirmar Match'}
                                </button>
                            </>
                        )}
                    </div>
                )}
            </div>
        </div>
    );
}
