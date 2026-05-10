import { Controller } from "@hotwired/stimulus";
import consumer from "channels/consumer";

const MAX_MESSAGES = 100;

const PLATFORM_ICONS = {
  tiktok: `<svg class="w-3.5 h-3.5 shrink-0" viewBox="0 0 24 24" fill="currentColor" style="color:#000"><path d="M19.59 6.69a4.83 4.83 0 01-3.77-4.25V2h-3.45v13.67a2.89 2.89 0 01-2.88 2.5 2.89 2.89 0 01-2.89-2.89 2.89 2.89 0 012.89-2.89c.28 0 .54.04.79.1V9.01a6.33 6.33 0 00-.79-.05 6.34 6.34 0 00-6.34 6.34 6.34 6.34 0 006.34 6.34 6.34 6.34 0 006.33-6.34V8.94a8.16 8.16 0 004.78 1.52V7.01a4.85 4.85 0 01-1.01-.32z"/></svg>`,
  facebook: `<svg class="w-3.5 h-3.5 shrink-0" viewBox="0 0 24 24" fill="currentColor" style="color:#1877F2"><path d="M24 12.073C24 5.405 18.627 0 12 0S0 5.405 0 12.073C0 18.1 4.388 23.094 10.125 24v-8.437H7.078v-3.49h3.047V9.41c0-3.025 1.792-4.697 4.533-4.697 1.312 0 2.686.235 2.686.235v2.97h-1.513c-1.491 0-1.956.93-1.956 1.886v2.269h3.328l-.532 3.49h-2.796V24C19.612 23.094 24 18.1 24 12.073z"/></svg>`,
  instagram: `<svg class="w-3.5 h-3.5 shrink-0" viewBox="0 0 24 24" fill="currentColor" style="color:#E1306C"><path d="M12 2.163c3.204 0 3.584.012 4.85.07 3.252.148 4.771 1.691 4.919 4.919.058 1.265.069 1.645.069 4.849 0 3.205-.012 3.584-.069 4.849-.149 3.225-1.664 4.771-4.919 4.919-1.266.058-1.644.07-4.85.07-3.204 0-3.584-.012-4.849-.07-3.26-.149-4.771-1.699-4.919-4.92-.058-1.265-.07-1.644-.07-4.849 0-3.204.013-3.583.07-4.849.149-3.227 1.664-4.771 4.919-4.919 1.266-.057 1.645-.069 4.849-.069zM12 0C8.741 0 8.333.014 7.053.072 2.695.272.273 2.69.073 7.052.014 8.333 0 8.741 0 12c0 3.259.014 3.668.072 4.948.2 4.358 2.618 6.78 6.98 6.98C8.333 23.986 8.741 24 12 24c3.259 0 3.668-.014 4.948-.072 4.354-.2 6.782-2.618 6.979-6.98.059-1.28.073-1.689.073-4.948 0-3.259-.014-3.667-.072-4.947-.196-4.354-2.617-6.78-6.979-6.98C15.668.014 15.259 0 12 0zm0 5.838a6.162 6.162 0 100 12.324 6.162 6.162 0 000-12.324zM12 16a4 4 0 110-8 4 4 0 010 8zm6.406-11.845a1.44 1.44 0 100 2.881 1.44 1.44 0 000-2.881z"/></svg>`,
};

export default class extends Controller {
  static targets = ["messagesList", "statusBadge", "statusText", "emptyState"];
  static values = { transmissionId: Number };

  connect() {
    // Guard against double-connect (Turbo Drive cache)
    if (this.subscription) return;

    const prerendered = this.messagesListTarget.querySelectorAll("[data-live-chat-prerendered]");
    this.messageCount = prerendered.length;
    if (this.messageCount > 0) {
      this.messagesListTarget.scrollTop = this.messagesListTarget.scrollHeight;
    }

    this.setStatus("connecting", "Łączenie...");

    this.subscription = consumer.subscriptions.create(
      { channel: "LiveChatChannel", transmission_id: this.transmissionIdValue },
      {
        received: (data) => this.appendMessage(data),
        connected: () => this.setStatus("connected", "Połączono"),
        disconnected: () => this.setStatus("offline", "Rozłączono"),
      }
    );
  }

  disconnect() {
    this.subscription?.unsubscribe();
    this.subscription = null;
  }

  appendMessage({ body, sender_name, sender_id, platform, registered, customer_id } = {}) {
    if (!body || !sender_name) return;

    if (this.hasEmptyStateTarget) {
      this.emptyStateTarget.remove();
    }

    if (this.messageCount >= MAX_MESSAGES) {
      this.messagesListTarget.firstElementChild?.remove();
    } else {
      this.messageCount++;
    }

    const icon = PLATFORM_ICONS[platform] || "";
    const statusIcon = platform === "tiktok"
      ? (registered
          ? `<svg xmlns="http://www.w3.org/2000/svg" class="w-3.5 h-3.5 inline-block align-middle mr-1 mb-0.5" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" style="color:oklch(var(--su))" title="Klient w bazie"><path d="M22 11.08V12a10 10 0 1 1-5.93-9.14"/><polyline points="22 4 12 14.01 9 11.01"/></svg>`
          : `<svg xmlns="http://www.w3.org/2000/svg" class="w-3.5 h-3.5 inline-block align-middle mr-1 mb-0.5 opacity-30" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2" stroke-linecap="round" stroke-linejoin="round" title="Niezarejestrowany"><circle cx="12" cy="12" r="10"/><line x1="15" y1="9" x2="9" y2="15"/><line x1="9" y1="9" x2="15" y2="15"/></svg>`)
      : "";

    const isClickable = registered || platform !== "tiktok";
    const btnClass = isClickable
      ? "font-semibold text-sm text-primary hover:underline mr-1 cursor-pointer"
      : "font-semibold text-sm text-base-content/40 mr-1 cursor-default";
    const actionAttr = isClickable ? `data-action="click->live-chat#selectUser"` : "";

    const el = document.createElement("div");
    el.className = "flex items-start gap-2 px-2 py-2 rounded-lg hover:bg-base-200/60 transition-colors group";
    el.innerHTML = `
      <div class="mt-0.5 opacity-70">${icon}</div>
      <div class="min-w-0 flex-1">
        ${statusIcon}<button type="button"
                class="${btnClass}"
                ${actionAttr}
                data-username="${this.escapeAttr(sender_id || "")}"
                data-platform="${this.escapeAttr(platform || "")}"
                data-customer-id="${this.escapeAttr(String(customer_id || ""))}"
                data-registered="${registered ? "true" : "false"}">
          @${this.escapeHtml(sender_name)}
        </button><span class="text-sm text-base-content/80 wrap-break-word">${this.escapeHtml(body)}</span>
      </div>
    `;

    this.messagesListTarget.appendChild(el);
    this.messagesListTarget.scrollTop = this.messagesListTarget.scrollHeight;
  }

  selectUser(event) {
    const { username, platform, customerId, registered } = event.currentTarget.dataset;
    if (!username) return;

    document.dispatchEvent(
      new CustomEvent("live-chat:select-user", {
        detail: {
          username: `@${username}`,
          platform,
          customerId: customerId || null,
          registered: registered === "true",
        },
      })
    );
  }

  setStatus(state, label) {
    if (!this.hasStatusTextTarget) return;
    this.statusTextTarget.textContent = label;

    const dot = this.statusBadgeTarget.querySelector("span:first-child");
    const badge = this.statusBadgeTarget;

    badge.className = "badge badge-sm gap-1";
    dot.className = "w-1.5 h-1.5 rounded-full inline-block";

    if (state === "connected") {
      badge.classList.add("badge-success");
      dot.classList.add("bg-success");
    } else if (state === "error") {
      badge.classList.add("badge-error");
      dot.classList.add("bg-error");
    } else {
      badge.classList.add("badge-ghost");
      dot.classList.add("bg-base-content/30");
    }
  }

  escapeHtml(str) {
    return String(str || "")
      .replace(/&/g, "&amp;")
      .replace(/</g, "&lt;")
      .replace(/>/g, "&gt;")
      .replace(/"/g, "&quot;");
  }

  escapeAttr(str) {
    return String(str || "").replace(/"/g, "&quot;");
  }
}
