import { useState, useEffect } from 'react';
import FileUpload from './components/FileUpload.jsx';
import UnmatchedRow from './components/UnmatchedRow.jsx';

export default function App() {
    const [view, setView] = useState('upload');
    const [lotes, setLotes] = useState([]);
    const [selectedLote, setSelectedLote] = useState(null);
    const [pendientes, setPendientes] = useState([]);
    const [pagina, setPagina] = useState(1);
    const [totalPaginas, setTotalPaginas] = useState(1);
    const [polling, setPolling] = useState(false);
    const [fuzzyProgress, setFuzzyProgress] = useState(null);
    const [busquedaLote, setBusquedaLote] = useState('');
    const [busquedaPendiente, setBusquedaPendiente] = useState('');

    const cargarLotes = async (q = '') => {
        try {
            const api = await import('./services/api.js');
            const data = await api.getLotes(1, q);
            setLotes(data.data || []);
            setTotalPaginas(data.meta?.last_page || 1);
            setPagina(data.meta?.current_page || 1);
        } catch {
            // silent
        }
    };

    useEffect(() => {
        cargarLotes(busquedaLote);
    }, [busquedaLote]);

    const uploadComplete = async (result) => {
        setView('lotes');
        await cargarLotes(busquedaLote);
        if (result.lote_id) {
            setSelectedLote(result.lote_id);
            setPolling(true);
            setFuzzyProgress(null);
        }
    };

    useEffect(() => {
        if (!polling || !selectedLote) return;
        const interval = setInterval(async () => {
            try {
                const api = await import('./services/api.js');
                const data = await api.getLoteStatus(selectedLote);
                if (data.data?.fuzzy_progress !== undefined) {
                    setFuzzyProgress(data.data.fuzzy_progress);
                }
                if (data.data?.estado === 'completed' || data.data?.estado === 'error') {
                    setPolling(false);
                    setFuzzyProgress(null);
                    cargarPendientes(selectedLote, 1);
                }
            } catch {
                setPolling(false);
                setFuzzyProgress(null);
            }
        }, 2000);
        return () => clearInterval(interval);
    }, [polling, selectedLote]);

    const cargarPendientes = async (loteId, page, q = busquedaPendiente) => {
        try {
            const api = await import('./services/api.js');
            const data = await api.getPendientes(loteId, page, q);
            setPendientes(data.data || []);
            setPagina(data.meta?.current_page || 1);
            setTotalPaginas(data.meta?.last_page || 1);
        } catch {
            // silent
        }
    };

    useEffect(() => {
        if (selectedLote) cargarPendientes(selectedLote, 1);
    }, [busquedaPendiente]);

    const selectLote = (loteId) => {
        setSelectedLote(loteId);
        cargarPendientes(loteId, 1);
    };

    const handleConfirmado = (ingresanteId, data) => {
        setPendientes((prev) =>
            prev.map((p) =>
                p.id === ingresanteId
                    ? { ...p, estado_match: data.estado_match, alumno_id: data.alumno_id }
                    : p
            )
        );
    };

    const pendingCount = pendientes.filter((p) => p.estado_match === 'pendiente').length;

    return (
        <div className="min-h-screen bg-gray-50">
            <header className="bg-white border-b border-gray-200">
                <div className="mx-auto max-w-7xl px-4 py-4 sm:px-6 lg:px-8">
                    <div className="flex items-center justify-between">
                        <h1 className="text-xl font-bold text-gray-900">
                            Motor de Cruce de Ingresantes
                        </h1>
                        <nav className="flex gap-2">
                            <button
                                onClick={() => { setView('upload'); setSelectedLote(null); }}
                                className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${view === 'upload' ? 'bg-indigo-100 text-indigo-700' : 'text-gray-600 hover:text-gray-900'}`}
                            >
                                Subir CSV
                            </button>
                            <button
                                onClick={() => setView('lotes')}
                                className={`rounded-lg px-3 py-1.5 text-sm font-medium transition-colors ${view === 'lotes' ? 'bg-indigo-100 text-indigo-700' : 'text-gray-600 hover:text-gray-900'}`}
                            >
                                Lotes
                            </button>
                        </nav>
                    </div>
                </div>
            </header>

            <main className="mx-auto max-w-7xl px-4 py-8 sm:px-6 lg:px-8">
                {view === 'upload' && (
                    <FileUpload onUploadComplete={uploadComplete} />
                )}

                {view === 'lotes' && (
                    <div className="grid grid-cols-1 lg:grid-cols-3 gap-6">
                        <div className="lg:col-span-1">
                            <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                                <h2 className="text-sm font-semibold text-gray-900 mb-3">Lotes</h2>

                                <div className="relative mb-3">
                                    <input
                                        type="search"
                                        placeholder="Buscar por fecha..."
                                        value={busquedaLote}
                                        onChange={(e) => setBusquedaLote(e.target.value)}
                                        className="w-full rounded-lg border border-gray-300 px-3 py-1.5 pr-8 text-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                                    />
                                    {busquedaLote && (
                                        <button
                                            onClick={() => setBusquedaLote('')}
                                            className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 text-xs"
                                        >
                                            ✕
                                        </button>
                                    )}
                                </div>

                                {lotes.length === 0 ? (
                                    <p className="text-sm text-gray-500">{busquedaLote ? 'Sin resultados.' : 'No hay lotes aún.'}</p>
                                ) : (
                                    <ul className="space-y-1">
                                        {lotes.map((l) => (
                                            <li key={l.id}>
                                                <button
                                                    onClick={() => selectLote(l.id)}
                                                    className={`w-full text-left rounded-lg px-3 py-2 text-sm transition-colors ${selectedLote === l.id ? 'bg-indigo-50 text-indigo-700 font-medium' : 'text-gray-600 hover:bg-gray-50'}`}
                                                >
                                                    <span className="block truncate">{l.fecha_examen}</span>
                                                    <span className="block text-xs text-gray-400 mt-0.5">
                                                        {l.estado} · {l.total_registros} registros
                                                    </span>
                                                </button>
                                            </li>
                                        ))}
                                    </ul>
                                )}
                            </div>
                        </div>

                        <div className="lg:col-span-2">
                            {polling && (
                                <div className="rounded-xl border border-indigo-200 bg-white p-4 mb-4">
                                    <div className="flex items-center gap-3 mb-2">
                                        <svg className="animate-spin h-5 w-5 text-indigo-600" viewBox="0 0 24 24" fill="none">
                                            <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                            <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                        </svg>
                                        <span className="text-sm text-indigo-700">
                                            {fuzzyProgress !== null
                                                ? `Procesando matches difusos… ${fuzzyProgress}%`
                                                : 'Procesando lote en segundo plano…'}
                                        </span>
                                    </div>
                                    {fuzzyProgress !== null && (
                                        <div className="w-full bg-indigo-100 rounded-full h-2">
                                            <div
                                                className="bg-indigo-600 h-2 rounded-full transition-all duration-500"
                                                style={{ width: `${fuzzyProgress}%` }}
                                            />
                                        </div>
                                    )}
                                </div>
                            )}

                            {!selectedLote && !polling && (
                                <div className="rounded-xl border border-gray-200 bg-white p-8 text-center shadow-sm">
                                    <p className="text-gray-500">Seleccioná un lote para ver los pendientes.</p>
                                </div>
                            )}

                            {selectedLote && (
                                <div className="space-y-3">
                                    <div className="rounded-xl border border-gray-200 bg-white p-4 shadow-sm">
                                        <div className="flex items-center justify-between mb-3">
                                            <h2 className="text-sm font-semibold text-gray-900">Pendientes ({pendingCount})</h2>
                                        </div>
                                        <div className="relative">
                                            <input
                                                type="search"
                                                placeholder="Buscar por nombre, apellido, código o EAP…"
                                                value={busquedaPendiente}
                                                onChange={(e) => setBusquedaPendiente(e.target.value)}
                                                className="w-full rounded-lg border border-gray-300 px-3 py-2 pr-8 text-sm focus:border-indigo-500 focus:ring-1 focus:ring-indigo-500"
                                            />
                                            {busquedaPendiente && (
                                                <button
                                                    onClick={() => setBusquedaPendiente('')}
                                                    className="absolute right-2 top-1/2 -translate-y-1/2 text-gray-400 hover:text-gray-600 text-xs"
                                                >
                                                    ✕
                                                </button>
                                            )}
                                        </div>
                                    </div>

                                    {pendientes.length > 0 ? (
                                        <>
                                            {pendientes.map((p) => (
                                                <UnmatchedRow key={p.id} ingresante={p} onConfirmado={handleConfirmado} />
                                            ))}
                                            {totalPaginas > 1 && (
                                                <div className="flex justify-center gap-2 pt-4">
                                                    <button disabled={pagina <= 1} onClick={() => cargarPendientes(selectedLote, pagina - 1)}
                                                        className="rounded-lg px-3 py-1.5 text-sm text-gray-600 hover:text-gray-900 disabled:opacity-50">
                                                        Anterior
                                                    </button>
                                                    <span className="px-2 py-1.5 text-sm text-gray-500">{pagina} / {totalPaginas}</span>
                                                    <button disabled={pagina >= totalPaginas} onClick={() => cargarPendientes(selectedLote, pagina + 1)}
                                                        className="rounded-lg px-3 py-1.5 text-sm text-gray-600 hover:text-gray-900 disabled:opacity-50">
                                                        Siguiente
                                                    </button>
                                                </div>
                                            )}
                                        </>
                                    ) : !polling && (
                                        <div className="rounded-xl border border-gray-200 bg-white p-8 text-center shadow-sm">
                                            <p className="text-gray-500">{busquedaPendiente ? 'Sin resultados para la búsqueda.' : 'No hay pendientes en este lote.'}</p>
                                        </div>
                                    )}
                                </div>
                            )}
                        </div>
                    </div>
                )}
            </main>
        </div>
    );
}
