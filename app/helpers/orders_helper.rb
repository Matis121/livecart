module OrdersHelper
  # Grupowanie kolorów względem typu akcji:
  # - Szary: wstępne etapy (draft, offer_sent)
  # - Żółty: oczekiwanie na płatność
  # - Zielony: opłacone/zakończone pozytywnie
  # - Niebieski: w trakcie realizacji
  # - Czerwony: anulowane/problemy
  STATUS_COLORS = {
    draft:              "bg-slate-600/10 border-slate-600/30",
    offer_sent:         "bg-slate-600/10 border-slate-600/30",
    payment_processing: "bg-amber-500/10 border-amber-600/30",
    paid:               "bg-emerald-600/10 border-emerald-600/30",
    in_fulfillment:     "bg-amber-700/10 border-amber-700/30",
    shipped:            "bg-blue-600/10 border-blue-600/30",
    delivered:          "bg-emerald-600/10 border-emerald-600/30",
    cancelled:          "bg-red-600/10 border-red-600/30",
    returned:           "bg-red-600/10 border-red-600/30"
  }.freeze

  def order_status_badge(order)
    colors = STATUS_COLORS[order.status.to_sym] || "bg-slate-500 border-slate-600"
    content_tag :span, order.status_name, class: "inline-block text-center px-4 py-2 rounded-full text-xs font-semibold text-white border min-w-full #{colors}"
  end
end
