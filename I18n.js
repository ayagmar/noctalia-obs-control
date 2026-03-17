.pragma library

function interpolate(text, interpolations) {
  let resolved = String(text !== undefined ? text : "");
  if (!interpolations) {
    return resolved;
  }

  for (const name in interpolations) {
    const value = interpolations[name] !== undefined && interpolations[name] !== null
                  ? String(interpolations[name])
                  : "";
    resolved = resolved.split("{" + name + "}").join(value);
  }

  return resolved;
}

function tr(pluginApi, key, fallback, interpolations) {
  if (pluginApi && pluginApi.hasTranslation && pluginApi.hasTranslation(key)) {
    return pluginApi.tr(key, interpolations);
  }

  return interpolate(fallback, interpolations);
}
