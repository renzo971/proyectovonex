import React, { useState, useEffect } from 'react';
import { createRoot } from 'react-dom/client';

function App() {
    const [lotes, setLotes] = useState([]);
    const [selectedLoteId, setSelectedLoteId] = useState(null);
    const [pendientes, setPendientes] = useState([]);
    const [page, setPage] = useState(1);
    const [totalPages, setTotalPages] = useState(1);
    const [uploading, setUploading] = useState(false);
    const [uploadProgress, setUploadProgress] = useState(null);
    const [statusMessage, setStatusMessage] = useState(null);
    const [statusError, setStatusError] = useState(null);

    // Fetch batch lotes list
    const fetchLotes = async () => {
        try {
            const res = await fetch('/api/cruce/lotes');
            const data = await res.json();
            setLotes(data);
        } catch (err) {
            console.error('Error fetching lotes:', err);
        }
    };

    // Fetch pending unresolved ingresantes for the selected lote
    const fetchPendientes = async (loteId, pageNum = 1) => {
        try {
            const res = await fetch(`/api/cruce/lotes/${loteId}/pendientes?page=${pageNum}`);
            const data = await res.json();
            setPendientes(data.data);
            setPage(data.current_page);
            setTotalPages(data.last_page);
        } catch (err) {
            console.error('Error fetching pending items:', err);
        }
    };

    useEffect(() => {
        fetchLotes();
    }, []);

    useEffect(() => {
        if (selectedLoteId) {
            fetchPendientes(selectedLoteId, 1);
        } else {
            setPendientes([]);
        }
    }, [selectedLoteId]);

    // Handle CSV file upload
    const handleUpload = async (e) => {
        const file = e.target.files[0];
        if (!file) return;

        setUploading(true);
        setUploadProgress(10);
        setStatusMessage("Subiendo archivo y despachando lote...");
        setStatusError(null);

        const formData = new FormData();
        formData.append('file', file);

        try {
            const res = await fetch('/api/cruce/upload', {
                method: 'POST',
                body: formData
            });

            if (res.status === 413) {
                throw new Error("El archivo excede el límite de 20 MB.");
            }

            const data = await res.json();
            if (!res.ok || data.success === false) {
                throw new Error(data.error || "Ocurrió un error al procesar el archivo.");
            }

            setUploadProgress(50);
            setStatusMessage("Archivo encolado exitosamente. Procesando en segundo plano...");

            // Poll lotes list until completed
            let attempts = 0;
            const interval = setInterval(async () => {
                attempts++;
                const statusRes = await fetch(`/api/cruce/lotes/${data.lote_id}/status`);
                const statusData = await statusRes.json();
                
                if (statusData.estado === 'completed') {
                    setUploadProgress(100);
                    setStatusMessage("Lote procesado exitosamente!");
                    clearInterval(interval);
                    setUploading(false);
                    fetchLotes();
                    setSelectedLoteId(data.lote_id);
                } else if (statusData.estado === 'error' || attempts > 30) {
                    clearInterval(interval);
                    setUploading(false);
                    setStatusError("Fallo en el procesamiento asíncrono.");
                }
            }, 2000);

        } catch (err) {
            setUploading(false);
            setUploadProgress(null);
            setStatusMessage(null);
            setStatusError(err.message);
        }
    };

    // Confirm match manually
    const handleConfirmMatch = async (ingresanteId, alumnoId) => {
        try {
            const res = await fetch(`/api/cruce/ingresantes/${ingresanteId}/confirmar`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ alumno_id: alumnoId })
            });
            const data = await res.json();
            if (data.success) {
                // Refresh lists
                fetchLotes();
                fetchPendientes(selectedLoteId, page);
            }
        } catch (err) {
            console.error('Error confirming match:', err);
        }
    };

    // Mark as no match
    const handleMarkNoMatch = async (ingresanteId) => {
        try {
            const res = await fetch(`/api/cruce/ingresantes/${ingresanteId}/confirmar`, {
                method: 'POST',
                headers: { 'Content-Type': 'application/json' },
                body: JSON.stringify({ marcar_no_ingresado: true })
            });
            const data = await res.json();
            if (data.success) {
                fetchLotes();
                fetchPendientes(selectedLoteId, page);
            }
        } catch (err) {
            console.error('Error marking as no match:', err);
        }
    };

    return (
        <div className="max-w-6xl w-full mx-auto py-8 px-4 sm:px-6 lg:px-8">
            {/* Header section with high-end glassmorphism */}
            <div className="backdrop-blur-md bg-white/70 dark:bg-zinc-900/70 shadow-lg rounded-2xl p-6 border border-zinc-200/50 dark:border-zinc-800/50 mb-8 transition-all hover:shadow-xl">
                <div className="flex flex-col md:flex-row md:items-center md:justify-between gap-6">
                    <div>
                        <h1 className="text-3xl font-bold tracking-tight bg-gradient-to-r from-indigo-500 via-purple-500 to-pink-500 bg-clip-text text-transparent">
                            Motor de Cruce Automático
                        </h1>
                        <p className="mt-1 text-zinc-500 dark:text-zinc-400 text-sm">
                            Consolidación de ingresantes UNMSM y validación de matrículas en Academia Vonex.
                        </p>
                    </div>
                    {/* Premium File Upload input */}
                    <div className="flex items-center gap-4">
                        <label className="cursor-pointer inline-flex items-center justify-center rounded-xl bg-gradient-to-r from-indigo-600 to-purple-600 px-5 py-3 text-sm font-semibold text-white shadow-md hover:from-indigo-500 hover:to-purple-500 transition-all focus:outline-none focus:ring-2 focus:ring-indigo-500/50 focus:ring-offset-2">
                            <span>Subir CSV Oficial</span>
                            <input type="file" accept=".csv" className="hidden" onChange={handleUpload} disabled={uploading} />
                        </label>
                    </div>
                </div>

                {/* Progress Indicators & Messages */}
                {uploading && (
                    <div className="mt-6 bg-zinc-50 dark:bg-zinc-800/30 rounded-xl p-4 border border-zinc-200/50 dark:border-zinc-800/50">
                        <div className="flex justify-between text-xs font-semibold text-zinc-600 dark:text-zinc-400 mb-1">
                            <span>{statusMessage}</span>
                            <span>{uploadProgress}%</span>
                        </div>
                        <div className="w-full bg-zinc-200 dark:bg-zinc-700 h-2 rounded-full overflow-hidden">
                            <div className="bg-gradient-to-r from-indigo-500 to-purple-500 h-full rounded-full transition-all duration-500" style={{ width: `${uploadProgress}%` }}></div>
                        </div>
                    </div>
                )}

                {statusError && (
                    <div className="mt-6 bg-rose-50 dark:bg-rose-950/20 text-rose-600 dark:text-rose-400 rounded-xl p-4 border border-rose-200/50 dark:border-rose-800/30 text-sm font-medium">
                        ⚠️ Error: {statusError}
                    </div>
                )}
            </div>

            {/* Split layout for batches list and pending items */}
            <div className="grid grid-cols-1 lg:grid-cols-12 gap-8">
                {/* Batches / Lotes panel */}
                <div className="lg:col-span-4 backdrop-blur-md bg-white/70 dark:bg-zinc-900/70 shadow-lg rounded-2xl p-6 border border-zinc-200/50 dark:border-zinc-800/50 h-fit">
                    <h2 className="text-xl font-bold mb-4 bg-gradient-to-r from-indigo-500 to-purple-500 bg-clip-text text-transparent">
                        Lotes de Examen
                    </h2>
                    {lotes.length === 0 ? (
                        <p className="text-zinc-500 dark:text-zinc-400 text-sm text-center py-6">
                            No hay lotes procesados. Sube un CSV para comenzar.
                        </p>
                    ) : (
                        <div className="space-y-3">
                            {lotes.map((lote) => (
                                <div
                                    key={lote.id}
                                    onClick={() => setSelectedLoteId(lote.id)}
                                    className={`cursor-pointer p-4 rounded-xl border transition-all ${
                                        selectedLoteId === lote.id
                                            ? 'bg-indigo-500/10 border-indigo-500 shadow-md'
                                            : 'bg-zinc-50/50 dark:bg-zinc-800/20 border-zinc-200/50 dark:border-zinc-800/50 hover:bg-zinc-50 dark:hover:bg-zinc-800/50'
                                    }`}
                                >
                                    <div className="flex justify-between items-start mb-2">
                                        <span className="font-bold text-sm text-zinc-800 dark:text-zinc-200">
                                            Examen: {lote.fecha_examen}
                                        </span>
                                        <span className={`px-2 py-0.5 rounded-full text-[10px] font-bold ${
                                            lote.estado === 'completed'
                                                ? 'bg-emerald-500/10 text-emerald-500'
                                                : lote.estado === 'error'
                                                ? 'bg-rose-500/10 text-rose-500'
                                                : 'bg-amber-500/10 text-amber-500 animate-pulse'
                                        }`}>
                                            {lote.estado}
                                        </span>
                                    </div>
                                    <div className="grid grid-cols-2 gap-2 text-xs text-zinc-500 dark:text-zinc-400">
                                        <div>Registros: <span className="font-semibold text-zinc-700 dark:text-zinc-300">{lote.total_registros}</span></div>
                                        <div>Match Exacto: <span className="font-semibold text-zinc-700 dark:text-zinc-300">{lote.total_match_exacto}</span></div>
                                        <div>Pendientes: <span className="font-semibold text-zinc-700 dark:text-zinc-300">{lote.total_pendientes}</span></div>
                                        <div>No Ingresados: <span className="font-semibold text-zinc-700 dark:text-zinc-300">{lote.total_no_ingresado}</span></div>
                                    </div>
                                    {lote.estado === 'completed' && (
                                        <div className="mt-3 flex justify-end">
                                            <a
                                                href={`/api/cruce/lotes/${lote.id}/exportar`}
                                                className="inline-flex items-center gap-1.5 px-3 py-1.5 bg-zinc-900 dark:bg-zinc-800 hover:bg-zinc-800 dark:hover:bg-zinc-700 text-white rounded-lg text-xs font-semibold shadow-sm transition-all"
                                                onClick={(e) => e.stopPropagation()}
                                            >
                                                📥 Reporte Final
                                            </a>
                                        </div>
                                    )}
                                </div>
                            ))}
                        </div>
                    )}
                </div>

                {/* Pending unresolved items list */}
                <div className="lg:col-span-8 backdrop-blur-md bg-white/70 dark:bg-zinc-900/70 shadow-lg rounded-2xl p-6 border border-zinc-200/50 dark:border-zinc-800/50">
                    <h2 className="text-xl font-bold mb-4 bg-gradient-to-r from-indigo-500 to-purple-500 bg-clip-text text-transparent">
                        Casos Pendientes
                    </h2>
                    {!selectedLoteId ? (
                        <p className="text-zinc-500 dark:text-zinc-400 text-sm text-center py-12">
                            Selecciona un lote de examen a la izquierda para resolver casos pendientes.
                        </p>
                    ) : pendientes.length === 0 ? (
                        <p className="text-zinc-500 dark:text-zinc-400 text-sm text-center py-12">
                            🎉 No quedan casos pendientes por resolver en este lote!
                        </p>
                    ) : (
                        <div className="space-y-6">
                            {pendientes.map((item) => (
                                <div key={item.id} className="p-5 bg-zinc-50/50 dark:bg-zinc-800/20 rounded-2xl border border-zinc-200/50 dark:border-zinc-800/50">
                                    <div className="flex flex-col md:flex-row md:justify-between md:items-start gap-4 mb-4">
                                        <div>
                                            <h3 className="font-bold text-lg text-zinc-800 dark:text-zinc-200">
                                                {item.apellidos}, {item.nombres}
                                            </h3>
                                            <div className="flex flex-wrap gap-2 mt-1.5 text-xs">
                                                <span className="bg-indigo-500/10 text-indigo-500 px-2 py-0.5 rounded-md font-semibold">Código: {item.codigo}</span>
                                                <span className="bg-purple-500/10 text-purple-500 px-2 py-0.5 rounded-md font-semibold">{item.eap}</span>
                                                <span className="bg-pink-500/10 text-pink-500 px-2 py-0.5 rounded-md font-semibold">Score: {item.puntaje}</span>
                                                <span className="bg-amber-500/10 text-amber-500 px-2 py-0.5 rounded-md font-semibold">Merito: {item.merito}</span>
                                            </div>
                                        </div>
                                        <button
                                            onClick={() => handleMarkNoMatch(item.id)}
                                            className="px-4 py-2 bg-rose-500/10 hover:bg-rose-500 text-rose-500 hover:text-white border border-rose-200 dark:border-rose-900/50 rounded-xl text-xs font-bold transition-all"
                                        >
                                            ❌ Marcar No Match
                                        </button>
                                    </div>

                                    {/* Suggested Candidates dropdown list */}
                                    <div className="mt-4">
                                        <h4 className="text-xs font-bold text-zinc-500 dark:text-zinc-400 mb-2 uppercase tracking-wider">
                                            Candidatos Sugeridos:
                                        </h4>
                                        {item.candidatos && item.candidatos.length > 0 ? (
                                            <div className="space-y-2">
                                                {item.candidatos.map((candidate) => (
                                                    <div key={candidate.id} className="flex justify-between items-center p-3 bg-white dark:bg-zinc-900 border border-zinc-200/50 dark:border-zinc-800/50 rounded-xl">
                                                        <div className="text-xs">
                                                            <div className="font-semibold text-zinc-800 dark:text-zinc-200">
                                                                ID Alumno: {candidate.alumno_id}
                                                            </div>
                                                            <div className="text-zinc-500 dark:text-zinc-400">
                                                                Similitud: <span className="font-bold text-indigo-500">{candidate.porcentaje_similitud}%</span>
                                                            </div>
                                                        </div>
                                                        <button
                                                            onClick={() => handleConfirmMatch(item.id, candidate.alumno_id)}
                                                            className="px-3 py-1.5 bg-indigo-500 hover:bg-indigo-600 text-white rounded-lg text-xs font-semibold shadow-sm transition-all"
                                                        >
                                                            Confirmar Match
                                                        </button>
                                                    </div>
                                                ))}
                                            </div>
                                        ) : (
                                            <p className="text-zinc-400 dark:text-zinc-500 text-xs italic">
                                                No se encontraron candidatos con similitud relevante.
                                            </p>
                                        )}
                                    </div>
                                </div>
                            ))}

                            {/* Pagination controls */}
                            {totalPages > 1 && (
                                <div className="flex justify-between items-center pt-4">
                                    <button
                                        disabled={page === 1}
                                        onClick={() => fetchPendientes(selectedLoteId, page - 1)}
                                        className="px-4 py-2 bg-zinc-100 dark:bg-zinc-800 rounded-lg text-xs font-bold disabled:opacity-50 transition-all"
                                    >
                                        ⬅️ Anterior
                                    </button>
                                    <span className="text-xs text-zinc-500">
                                        Pág {page} de {totalPages}
                                    </span>
                                    <button
                                        disabled={page === totalPages}
                                        onClick={() => fetchPendientes(selectedLoteId, page + 1)}
                                        className="px-4 py-2 bg-zinc-100 dark:bg-zinc-800 rounded-lg text-xs font-bold disabled:opacity-50 transition-all"
                                    >
                                        Siguiente ➡️
                                    </button>
                                </div>
                            )}
                        </div>
                    )}
                </div>
            </div>
        </div>
    );
}

const container = document.getElementById('root') || document.body;
const root = createRoot(container);
root.render(<App />);
