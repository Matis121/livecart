module OrdersHelper
  # Grupowanie kolorów względem typu akcji:
  # - Szary: wstępne etapy (draft, offer_sent)
  # - Żółty: oczekiwanie na płatność
  # - Zielony: opłacone/zakończone pozytywnie
  # - Niebieski: w trakcie realizacji
  # - Czerwony: anulowane/problemy
  STATUS_COLORS = {
    draft:              "bg-slate-200 text-slate-700 border-slate-300",
    offer_sent:         "bg-slate-200 text-slate-700 border-slate-300",
    payment_processing: "bg-amber-100 text-amber-800 border-amber-300",
    in_fulfillment:     "bg-orange-100 text-orange-800 border-orange-300",
    shipped:            "bg-blue-100 text-blue-800 border-blue-300",
    delivered:          "bg-emerald-500 text-white border-emerald-600",
    cancelled:          "bg-red-100 text-red-800 border-red-300",
    returned:           "bg-red-100 text-red-800 border-red-300"
  }.freeze

  def order_status_badge(order)
    colors = STATUS_COLORS[order.status.to_sym] || "bg-slate-200 text-slate-700 border-slate-300"
    content_tag :span, order.status_name, class: "inline-block text-center px-4 py-2 rounded-full text-xs font-semibold border min-w-full #{colors}"
  end
end
