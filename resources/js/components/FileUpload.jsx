import { useState, useRef } from 'react';

export default function FileUpload({ onUploadComplete }) {
    const [file, setFile] = useState(null);
    const [uploading, setUploading] = useState(false);
    const [result, setResult] = useState(null);
    const [error, setError] = useState(null);
    const inputRef = useRef(null);

    const handleSubmit = async (e) => {
        e.preventDefault();
        if (!file) return;

        setUploading(true);
        setError(null);
        setResult(null);

        try {
            const { uploadCsv } = await import('../services/api.js');
            const data = await uploadCsv(file);

            setResult(data);
            if (onUploadComplete) {
                onUploadComplete(data);
            }
        } catch (err) {
            setError(err.message);
        } finally {
            setUploading(false);
        }
    };

    const reset = () => {
        setFile(null);
        setResult(null);
        setError(null);
        if (inputRef.current) inputRef.current.value = '';
    };

    return (
        <div className="rounded-xl border border-gray-200 bg-white p-6 shadow-sm">
            <h2 className="mb-4 text-lg font-semibold text-gray-900">Subir CSV de Ingresantes</h2>

            {!result ? (
                <form onSubmit={handleSubmit} className="space-y-4">
                    <div>
                        <label className="block text-sm font-medium text-gray-700 mb-1">
                            Archivo CSV
                        </label>
                        <input
                            ref={inputRef}
                            type="file"
                            accept=".csv"
                            onChange={(e) => setFile(e.target.files[0])}
                            className="block w-full text-sm text-gray-500 file:mr-4 file:rounded-lg file:border-0 file:bg-indigo-50 file:px-4 file:py-2 file:text-sm file:font-semibold file:text-indigo-700 hover:file:bg-indigo-100"
                            required
                        />
                        <p className="mt-1 text-xs text-gray-500">
                            Solo archivos .csv con las 12 columnas requeridas. Máximo 20 MB.
                        </p>
                    </div>

                    {error && (
                        <div className="rounded-lg bg-red-50 p-3 text-sm text-red-700 border border-red-200">
                            {error}
                        </div>
                    )}

                    <button
                        type="submit"
                        disabled={!file || uploading}
                        className="inline-flex items-center gap-2 rounded-lg bg-indigo-600 px-4 py-2 text-sm font-medium text-white hover:bg-indigo-700 disabled:opacity-50 disabled:cursor-not-allowed transition-colors"
                    >
                        {uploading ? (
                            <>
                                <svg className="animate-spin h-4 w-4" viewBox="0 0 24 24" fill="none">
                                    <circle className="opacity-25" cx="12" cy="12" r="10" stroke="currentColor" strokeWidth="4" />
                                    <path className="opacity-75" fill="currentColor" d="M4 12a8 8 0 018-8V0C5.373 0 0 5.373 0 12h4z" />
                                </svg>
                                Procesando…
                            </>
                        ) : (
                            'Subir y Procesar'
                        )}
                    </button>
                </form>
            ) : (
                <div className="space-y-4">
                    <div className="rounded-lg bg-green-50 p-4 border border-green-200 space-y-3">
                        <h3 className="font-medium text-green-800">CSV procesado exitosamente</h3>

                        <div className="bg-white rounded-lg p-3 border border-green-100">
                            <h4 className="text-xs font-semibold text-gray-500 uppercase tracking-wide mb-2">Filtro por OBSERVACION</h4>
                            <div className="flex gap-4">
                                <div className="flex-1 text-center">
                                    <p className="text-2xl font-bold text-green-600">{result.data?.total_ingresantes ?? 0}</p>
                                    <p className="text-xs text-gray-500 mt-0.5">ALCANZO VACANTE</p>
                                </div>
                                <div className="w-px bg-green-200" />
                                <div className="flex-1 text-center">
                                    <p className="text-2xl font-bold text-gray-500">{result.data?.total_no_ingresantes ?? 0}</p>
                                    <p className="text-xs text-gray-500 mt-0.5">NO ALCANZO VACANTE</p>
                                </div>
                            </div>
                        </div>

                        <dl className="grid grid-cols-2 gap-x-4 gap-y-1.5 text-sm">
                            <dt className="text-gray-500">Total registros únicos:</dt>
                            <dd className="font-medium text-right">{result.data?.total_registros ?? 0}</dd>
                            <dt className="text-gray-500">Duplicados removidos:</dt>
                            <dd className="font-medium text-right text-amber-600">{result.data?.duplicates_removed ?? 0}</dd>
                            <dt className="text-gray-500">Lotes creados:</dt>
                            <dd className="font-medium text-right">{result.lote_id ? 1 : 0}</dd>
                        </dl>
                    </div>

                    {result.data?.errores?.length > 0 && (
                        <div className="rounded-lg bg-yellow-50 p-3 border border-yellow-200">
                            <h4 className="text-sm font-medium text-yellow-800 mb-1">Advertencias</h4>
                            <ul className="text-xs text-yellow-700 list-disc list-inside">
                                {result.data.errores.map((err, i) => (
                                    <li key={i}>Fila {err.fila}: {err.mensaje}</li>
                                ))}
                            </ul>
                        </div>
                    )}

                    <button
                        onClick={reset}
                        className="text-sm text-indigo-600 hover:text-indigo-800 font-medium"
                    >
                        Subir otro archivo
                    </button>
                </div>
            )}
        </div>
    );
}
