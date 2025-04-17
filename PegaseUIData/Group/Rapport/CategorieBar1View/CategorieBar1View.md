<!--import SwiftUI-->
<!--import SwiftData-->
<!--import DGCharts-->
<!---->
<!---->
<!---->
<!-- pour afficher un graph il faut :-->
<!---->
<!--### Model               : class  CategorieBar1ViewModel  : ObservableObject -->
<!---->
<!--### View                : struct CategorieBar1View       : View -->
<!---->
<!--### View1               : struct CategorieBar1View1      : View -->
<!--    func updateChartDebounced()-->
<!--    private func exportChartAsImage()-->
<!--    private func findChartView(in window: NSWindow?) -> BarChartView?-->
<!--    private func updateChart()-->
<!--    func formattedDate(from dayOffset: Double) -> String {-->
<!---->
<!---->
<!---->
<!--NSViewRepresentable : struct DGBarChartView          : NSViewRepresentable {-->
<!--    func makeNSView(context: Context) -> BarChartView -->
<!--    func updateNSView(_ nsView: BarChartView, context: Context) -->
<!--        func initChart() -->
<!--        func initializeLegend(_ legend: Legend) {-->
<!--        func setUpAxis() -->
<!--        func setDataCount()-->




