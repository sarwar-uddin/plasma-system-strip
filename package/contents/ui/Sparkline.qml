import QtQuick

// Tiny panel-sized history line: baseline + filled smoothed line + head dot. Fixed 0–100 scale.
Canvas {
    id: spark

    property var values: []
    property string rgb: "224,32,63"
    property int samples: 30

    implicitWidth: 36
    implicitHeight: 16

    onValuesChanged: requestPaint()
    onWidthChanged: requestPaint()
    onHeightChanged: requestPaint()

    onPaint: {
        const ctx = getContext("2d")
        ctx.reset()
        const w = width, h = height
        const top = 2, bottom = h - 1.5
        const d = (values || []).slice(-samples)

        ctx.strokeStyle = "rgba(124,124,132,0.5)"
        ctx.lineWidth = 1
        ctx.beginPath(); ctx.moveTo(0, bottom + 0.5); ctx.lineTo(w, bottom + 0.5); ctx.stroke()
        if (d.length < 2) return

        const step = (w - 3) / (samples - 1)
        const x0 = (w - 3) - (d.length - 1) * step
        const yOf = v => bottom - Math.max(0, Math.min(v, 100)) / 100 * (bottom - top)

        ctx.beginPath()
        ctx.moveTo(x0, yOf(d[0]))
        for (let i = 1; i < d.length; i++) {
            const xp = x0 + (i - 1) * step, xc = x0 + i * step, xm = (xp + xc) / 2
            ctx.bezierCurveTo(xm, yOf(d[i - 1]), xm, yOf(d[i]), xc, yOf(d[i]))
        }
        ctx.strokeStyle = "rgb(" + rgb + ")"
        ctx.lineWidth = 1.5
        ctx.stroke()
        ctx.lineTo(x0 + (d.length - 1) * step, bottom)
        ctx.lineTo(x0, bottom)
        ctx.closePath()
        const g = ctx.createLinearGradient(0, top, 0, bottom)
        g.addColorStop(0, "rgba(" + rgb + ",0.5)")
        g.addColorStop(1, "rgba(" + rgb + ",0.05)")
        ctx.fillStyle = g
        ctx.fill()

        const hx = x0 + (d.length - 1) * step, hy = yOf(d[d.length - 1])
        ctx.fillStyle = "rgb(" + rgb + ")"
        ctx.beginPath(); ctx.arc(hx, hy, 1.8, 0, 2 * Math.PI); ctx.fill()
    }
}
