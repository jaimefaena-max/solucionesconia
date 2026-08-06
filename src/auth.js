export function validateClientSession() { const token = localStorage.getItem('zasa_token'); if (!token) { window.location.href = '/login'; } return token; } 
