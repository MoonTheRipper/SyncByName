const repository = "MoonTheRipper/SyncByName";
const fallbackVersion = "0.1.0";

const releaseStatus = document.getElementById("release-status");
const primaryDownload = document.getElementById("primary-download");

const fallbackAsset = `downloads/SyncByName-${fallbackVersion}-macOS-arm64.zip`;

function setFallback() {
  primaryDownload.href = fallbackAsset;
  primaryDownload.textContent = `Download ${fallbackVersion}`;
  releaseStatus.textContent = `Latest release API unavailable. Falling back to local asset path for ${fallbackVersion}.`;
}

fetch(`https://api.github.com/repos/${repository}/releases/latest`)
  .then((response) => {
    if (!response.ok) {
      throw new Error(`GitHub returned ${response.status}`);
    }
    return response.json();
  })
  .then((release) => {
    const zipAsset = (release.assets || []).find((asset) => asset.name.endsWith(".zip"));
    primaryDownload.href = zipAsset ? zipAsset.browser_download_url : release.html_url;
    primaryDownload.textContent = `Download ${release.tag_name}`;
    releaseStatus.textContent = `Latest release: ${release.tag_name}`;
  })
  .catch(() => {
    setFallback();
  });
