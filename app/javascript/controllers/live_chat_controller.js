import { Controller } from "@hotwired/stimulus";
import { createConsumer } from "@rails/actioncable";

export default class extends Controller {
  static targets = ["feed", "bubble"];
  static values = {
    transmissionId: Number,
  };

  connect() {
    this.consumer = createConsumer();
    this.subscription = this.consumer.subscriptions.create(
      {
        channel: "LiveChatChannel",
        transmission_id: this.transmissionIdValue,
      },
      {
        received: (data) => this.appendMessage(data),
      }
    );
  }

  disconnect() {
    this.subscription?.unsubscribe();
    this.consumer?.disconnect();
  }

  appendMessage(data) {
    if (!this.hasFeedTarget) return;

    const bubble = this.buildBubble(data);
    this.feedTarget.appendChild(bubble);
    this.feedTarget.scrollTop = this.feedTarget.scrollHeight;
  }

  buildBubble(data) {
    const div = document.createElement("div");
    div.className =
      "flex items-start gap-2 p-2 rounded-lg hover:bg-base-200 group";
    div.dataset.messageId = data.message_id;

    const avatar = data.avatar_url
      ? `<img src="${data.avatar_url}" class="w-8 h-8 rounded-full flex-shrink-0 object-cover" alt="${data.username}">`
      : `<div class="w-8 h-8 rounded-full flex-shrink-0 bg-base-300 flex items-center justify-center text-xs font-bold">${(data.username || "?")[0].toUpperCase()}</div>`;

    const assignUrl = `/transmissions/${this.transmissionIdValue}/live_assignments/new_assignment?` +
      new URLSearchParams({
        user_id:    data.user_id,
        username:   data.username,
        avatar_url: data.avatar_url || "",
        platform:   data.platform,
      }).toString();

    div.innerHTML = `
      ${avatar}
      <div class="flex-1 min-w-0">
        <span class="font-semibold text-xs text-base-content/70">${escapeHtml(data.username || "")}</span>
        <p class="text-sm break-words">${escapeHtml(data.text || "")}</p>
      </div>
      <a href="${assignUrl}"
         data-turbo-frame="live_assignment_modal"
         class="btn btn-xs btn-ghost opacity-0 group-hover:opacity-100 flex-shrink-0"
         title="Przypisz do produktu">
        +
      </a>
    `;

    return div;
  }
}

function escapeHtml(str) {
  const div = document.createElement("div");
  div.appendChild(document.createTextNode(str));
  return div.innerHTML;
}
