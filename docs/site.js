const repository = "MoonTheRipper/SyncByName";
const fallbackVersion = "0.2.0";
const storageKey = "syncbyname.theme";

const releaseStatus = document.getElementById("release-status");
const zipDownload = document.getElementById("download-zip");
const dmgDownload = document.getElementById("download-dmg");
const sourceDownload = document.getElementById("download-source");
const themeToggle = document.getElementById("theme-toggle");

function applyTheme(theme) {
  document.documentElement.dataset.theme = theme;
  localStorage.setItem(storageKey, theme);
}

function initialTheme() {
  const saved = localStorage.getItem(storageKey);
  if (saved === "light" || saved === "dark") {
    return saved;
  }
  return window.matchMedia("(prefers-color-scheme: dark)").matches ? "dark" : "light";
}

function setFallback() {
  zipDownload.href = `downloads/SyncByName-${fallbackVersion}-macOS-arm64.zip`;
  dmgDownload.href = `downloads/SyncByName-${fallbackVersion}-macOS-arm64.dmg`;
  sourceDownload.href = `https://github.com/${repository}/archive/refs/tags/v${fallbackVersion}.zip`;
  releaseStatus.textContent = `Latest release API unavailable. Falling back to local ${fallbackVersion} assets.`;
}

applyTheme(initialTheme());

themeToggle?.addEventListener("click", () => {
  applyTheme(document.documentElement.dataset.theme === "dark" ? "light" : "dark");
});

fetch(`https://api.github.com/repos/${repository}/releases/latest`)
  .then((response) => {
    if (!response.ok) {
      throw new Error(`GitHub returned ${response.status}`);
    }
    return response.json();
  })
  .then((release) => {
    const zipAsset = (release.assets || []).find((asset) => asset.name.endsWith(".zip"));
    const dmgAsset = (release.assets || []).find((asset) => asset.name.endsWith(".dmg"));
    const sourceURL = `https://github.com/${repository}/archive/refs/tags/${release.tag_name}.zip`;

    zipDownload.href = zipAsset ? zipAsset.browser_download_url : release.html_url;
    dmgDownload.href = dmgAsset ? dmgAsset.browser_download_url : release.html_url;
    sourceDownload.href = sourceURL;
    releaseStatus.textContent = `Latest release: ${release.tag_name}`;
  })
  .catch(() => {
    setFallback();
  });
