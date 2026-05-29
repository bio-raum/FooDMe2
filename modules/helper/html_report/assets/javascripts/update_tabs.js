// Force plotly to recompute layout if a new panel tab is active
// https://github.com/quarto-dev/quarto-cli/issues/4705#issuecomment-1938542840
// adapted from https://stackoverflow.com/a/62572610/602276

$(document).on('shown.bs.tab', function (event) {
    console.log("Tab shown");
    var doc = $(".tab-pane.active .plotly-graph-div");
    for (var i = 0; i < doc.length; i++) {
        _Plotly.relayout(doc[i], {autosize: true});
    }
});