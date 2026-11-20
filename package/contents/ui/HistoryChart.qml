import QtQuick

// Meteogram-style history chart: dark grid, filled primary series, line secondary series.
Canvas {
    id: chart

    // [{ data: [..], rgb: "200,16,46", fill: bool }]
    property var series: []
    property int capacity: 90
    property real fixedMax: -1          // -1 = auto scale
    property real minScale: 1           // smallest auto-scaled maximum (keeps axis labels distinct)
    property var labelFormatter: function (v) { return Math.round(v) + "%" }
    property int gridRows: 4
    property int gridColEvery: 15       // vertical grid line every N samples
    property int labelWidth: 52

    readonly property color gridColor: "#2A2A2E"
    readonly property color gridStrong: "#4A4A50"
    readonly property color labelColor: "#9A9AA2"

    property real currentMax: 1

    function niceMax(v) {
        if (v <= 0) return 1
        const p = Math.pow(10, Math.floor(Math.log10(v)))
        const n = v / p
        const m = n <= 1 ? 1 : n <= 2 ? 2 : n <= 5 ? 5 : 10
        return m * p
    }

    onSeriesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        const left = labelWidth, top = 6, bottom = h - 4
        const plotW = w - left - 4, plotH = bottom - top

        let mx = fixedMax
        if (mx <= 0) {
            mx = 0
            for (const s of series) for (const v of s.data) mx = Math.max(mx, v)
            mx = Math.max(niceMax(mx * 1.15), minScale)
        }
        currentMax = mx

        // grid
        ctx.lineWidth = 1
        ctx.font = "10px sans-serif"
        ctx.textAlign = "right"
        ctx.textBaseline = "middle"
        for (let r = 0; r <= gridRows; r++) {
            const y = Math.round(top + plotH * r / gridRows) + 0.5
            ctx.strokeStyle = (r === gridRows) ? gridStrong : gridColor
            ctx.beginPath(); ctx.moveTo(left, y); ctx.lineTo(left + plotW, y); ctx.stroke()
            ctx.fillStyle = labelColor
            ctx.fillText(labelFormatter(mx * (gridRows - r) / gridRows), left - 6, y)
        }
        const step = plotW / (capacity - 1)
        for (let c = 0; c < capacity; c += gridColEvery) {
            const x = Math.round(left + plotW - c * step) + 0.5
            ctx.strokeStyle = c === 0 ? gridStrong : gridColor
            ctx.beginPath(); ctx.moveTo(x, top); ctx.lineTo(x, bottom); ctx.stroke()
        }
        ctx.strokeStyle = gridStrong
        ctx.beginPath(); ctx.moveTo(left + 0.5, top); ctx.lineTo(left + 0.5, bottom); ctx.stroke()

        // series (newest sample at the right edge), clipped to the plot area
        ctx.save()
        ctx.beginPath(); ctx.rect(left, top - 6, plotW + 4, plotH + 10); ctx.clip()
        for (const s of series) {
            const d = (s.data || []).slice(-capacity)
            if (d.length < 2) continue
            const x0 = left + plotW - (d.length - 1) * step
            const yOf = v => bottom - Math.min(v / mx, 1) * plotH
            ctx.beginPath()
            ctx.moveTo(x0, yOf(d[0]))
            for (let i = 1; i < d.length; i++) {
                const xp = x0 + (i - 1) * step, xc = x0 + i * step
                const xm = (xp + xc) / 2
                ctx.bezierCurveTo(xm, yOf(d[i - 1]), xm, yOf(d[i]), xc, yOf(d[i]))
            }
            ctx.strokeStyle = "rgb(" + s.rgb + ")"
            ctx.lineWidth = s.fill ? 2 : 1.5
            ctx.stroke()
            if (s.fill) {
                ctx.lineTo(left + plotW, bottom)
                ctx.lineTo(x0, bottom)
                ctx.closePath()
                const g = ctx.createLinearGradient(0, top, 0, bottom)
                g.addColorStop(0, "rgba(" + s.rgb + ",0.55)")
                g.addColorStop(1, "rgba(" + s.rgb + ",0.04)")
                ctx.fillStyle = g
                ctx.fill()
            }
            // glowing head dot
            const hx = left + plotW, hy = yOf(d[d.length - 1])
            ctx.fillStyle = "rgba(" + s.rgb + ",0.25)"
            ctx.beginPath(); ctx.arc(hx - 1, hy, 5, 0, 2 * Math.PI); ctx.fill()
            ctx.fillStyle = "rgb(" + s.rgb + ")"
            ctx.beginPath(); ctx.arc(hx - 1, hy, 2.2, 0, 2 * Math.PI); ctx.fill()
        }
        ctx.restore()
    }
}
