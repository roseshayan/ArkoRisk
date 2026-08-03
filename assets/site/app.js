(() => {
  const root = document.documentElement;
  const button = document.querySelector(".theme");
  const saved = localStorage.getItem("arkorisk-theme");
  if (saved === "light" || saved === "dark") root.dataset.theme = saved;

  const sync = () => {
    const light = root.dataset.theme === "light";
    button?.setAttribute("aria-pressed", String(light));
    const label = button?.querySelector("span");
    if (label) label.textContent = light ? "تم تیره" : "تم روشن";
  };

  button?.addEventListener("click", () => {
    root.dataset.theme = root.dataset.theme === "light" ? "dark" : "light";
    localStorage.setItem("arkorisk-theme", root.dataset.theme);
    sync();
  });
  sync();
})();

