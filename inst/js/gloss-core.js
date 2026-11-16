(function () {
  "use strict";

  var config = window.__GLOSS_RUNTIME_CONFIG__ || {};
  var root = document.querySelector(".gloss-figure");
  var tooltip = null;

  function targets(ids) {
    if (!Array.isArray(ids)) return [];
    return ids.map(function (id) {
      if (!root) return null;
      var nodes = root.querySelectorAll("[data-gloss-element]");
      for (var i = 0; i < nodes.length; i += 1) {
        if (nodes[i].getAttribute("data-gloss-element") === String(id)) return nodes[i];
      }
      return null;
    }).filter(Boolean);
  }

  function classes(node, add, remove) {
    (add || []).forEach(function (name) { node.classList.add(name); });
    (remove || []).forEach(function (name) { node.classList.remove(name); });
  }

  function showTooltip(node, text) {
    if (!text || !root) return;
    if (!tooltip) {
      tooltip = document.createElement("div");
      tooltip.className = "gloss-tooltip";
      tooltip.setAttribute("role", "status");
      root.appendChild(tooltip);
    }
    tooltip.textContent = text;
    tooltip.hidden = false;
    var rect = node.getBoundingClientRect();
    var host = root.getBoundingClientRect();
    tooltip.style.left = (rect.left - host.left + rect.width / 2) + "px";
    tooltip.style.top = (rect.top - host.top - 8) + "px";
  }

  function hideTooltip() {
    if (tooltip) tooltip.hidden = true;
  }

  function applyOperation(operation) {
    var nodes = targets(operation.targets);
    if (!nodes.length) return;
    if (operation.op === "select") {
      nodes.forEach(function (node) {
        classes(node, ["gloss-selected"], []);
        node.setAttribute("aria-selected", "true");
      });
    } else if (operation.op === "style") {
      nodes.forEach(function (node) { classes(node, ["gloss-" + operation.style], []); });
    } else if (operation.op === "show") {
      nodes.forEach(function (node) { classes(node, ["gloss-shown"], ["gloss-hidden"]); });
    } else if (operation.op === "hide") {
      nodes.forEach(function (node) { classes(node, ["gloss-hidden"], ["gloss-shown"]); });
    } else if (operation.op === "focus") {
      nodes.forEach(function (node) { node.setAttribute("tabindex", "0"); node.focus(); });
    }
  }

  function install(operation) {
    var nodes = targets(operation.targets);
    nodes.forEach(function (node) {
      node.setAttribute("data-gloss-operation", operation.op);
      if (operation.op === "tooltip") {
        node.addEventListener("mouseenter", function () { showTooltip(node, operation.text || ""); });
        node.addEventListener("mouseleave", hideTooltip);
        node.addEventListener("focus", function () { showTooltip(node, operation.text || ""); });
        node.addEventListener("blur", hideTooltip);
      }
      if (["select", "style", "show", "hide", "focus"].indexOf(operation.op) >= 0) {
        node.addEventListener("click", function () { applyOperation(operation); });
        node.addEventListener("keydown", function (event) {
          if (event.key === "Enter" || event.key === " ") {
            event.preventDefault();
            applyOperation(operation);
          }
        });
      }
    });
  }

  function init() {
    if (!root) return;
    (config.operations || []).forEach(install);
    window.gloss = {
      version: "0.1.0",
      apply: applyOperation,
      operations: config.operations || []
    };
  }

  if (document.readyState === "loading") document.addEventListener("DOMContentLoaded", init);
  else init();
}());
