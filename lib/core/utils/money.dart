/// Redondea un importe monetario a 2 decimales de forma estable, evitando la
/// acumulación de errores de punto flotante (p. ej. 0.1 + 0.2 = 0.30000000004).
///
/// Es una mitigación: la solución definitiva sería manejar el dinero en enteros
/// (centavos). Úsalo al calcular sumas/totales y al guardar importes.
double roundMoney(num value) => (value * 100).round() / 100;
