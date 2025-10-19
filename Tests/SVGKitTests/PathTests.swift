//
//  PathTests.swift
//  SVGKit
//
//  Created by maralla on 2025/4/7.
//

import Foundation
import Testing

@testable import SVGKit

struct PathTests {
    //    @Test func playSVG() async throws {
    //        let data = """
    //<svg aria-roledescription="block" role="graphics-document document" style="overflow: hidden; max-width: 100%;" xmlns="http://www.w3.org/2000/svg" width="100%" id="graph-3" height="100%" xmlns:xlink="http://www.w3.org/1999/xlink" xmlns:ev="http://www.w3.org/2001/xml-events"><g id="viewport-20250406163524469" class="svg-pan-zoom_viewport" transform="matrix(1.275287351358932,0,0,1.275287351358932,-24.041489393035256,432.17137393612484)" style="transform: matrix(1.275287, 0, 0, 1.275287, -24.041489, 432.171374);"><style>#graph-3{font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:16px;fill:#333;}@keyframes edge-animation-frame{from{stroke-dashoffset:0;}}@keyframes dash{to{stroke-dashoffset:0;}}#graph-3 .edge-animation-slow{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 50s linear infinite;stroke-linecap:round;}#graph-3 .edge-animation-fast{stroke-dasharray:9,5!important;stroke-dashoffset:900;animation:dash 20s linear infinite;stroke-linecap:round;}#graph-3 .error-icon{fill:#552222;}#graph-3 .error-text{fill:#552222;stroke:#552222;}#graph-3 .edge-thickness-normal{stroke-width:1px;}#graph-3 .edge-thickness-thick{stroke-width:3.5px;}#graph-3 .edge-pattern-solid{stroke-dasharray:0;}#graph-3 .edge-thickness-invisible{stroke-width:0;fill:none;}#graph-3 .edge-pattern-dashed{stroke-dasharray:3;}#graph-3 .edge-pattern-dotted{stroke-dasharray:2;}#graph-3 .marker{fill:#333333;stroke:#333333;}#graph-3 .marker.cross{stroke:#333333;}#graph-3 svg{font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:16px;}#graph-3 p{margin:0;}#graph-3 .label{font-family:"trebuchet ms",verdana,arial,sans-serif;color:#333;}#graph-3 .cluster-label text{fill:#333;}#graph-3 .cluster-label span,#graph-3 p{color:#333;}#graph-3 .label text,#graph-3 span,#graph-3 p{fill:#333;color:#333;}#graph-3 .node rect,#graph-3 .node circle,#graph-3 .node ellipse,#graph-3 .node polygon,#graph-3 .node path{fill:#ECECFF;stroke:#9370DB;stroke-width:1px;}#graph-3 .flowchart-label text{text-anchor:middle;}#graph-3 .node .label{text-align:center;}#graph-3 .node.clickable{cursor:pointer;}#graph-3 .arrowheadPath{fill:#333333;}#graph-3 .edgePath .path{stroke:#333333;stroke-width:2.0px;}#graph-3 .flowchart-link{stroke:#333333;fill:none;}#graph-3 .edgeLabel{background-color:rgba(232,232,232, 0.8);text-align:center;}#graph-3 .edgeLabel rect{opacity:0.5;background-color:rgba(232,232,232, 0.8);fill:rgba(232,232,232, 0.8);}#graph-3 .labelBkg{background-color:rgba(232, 232, 232, 0.5);}#graph-3 .node .cluster{fill:rgba(255, 255, 222, 0.5);stroke:rgba(170, 170, 51, 0.2);box-shadow:rgba(50, 50, 93, 0.25) 0px 13px 27px -5px,rgba(0, 0, 0, 0.3) 0px 8px 16px -8px;stroke-width:1px;}#graph-3 .cluster text{fill:#333;}#graph-3 .cluster span,#graph-3 p{color:#333;}#graph-3 div.mermaidTooltip{position:absolute;text-align:center;max-width:200px;padding:2px;font-family:"trebuchet ms",verdana,arial,sans-serif;font-size:12px;background:hsl(80, 100%, 96.2745098039%);border:1px solid #aaaa33;border-radius:2px;pointer-events:none;z-index:100;}#graph-3 .flowchartTitleText{text-anchor:middle;font-size:18px;fill:#333;}#graph-3 :root{--mermaid-font-family:"trebuchet ms",verdana,arial,sans-serif;}</style><g></g><marker orient="auto" markerHeight="12" markerWidth="12" markerUnits="userSpaceOnUse" refY="5" refX="6" viewBox="0 0 10 10" class="marker block" id="graph-3_block-pointEnd"></path></marker><marker orient="auto" markerHeight="12" markerWidth="12" markerUnits="userSpaceOnUse" refY="5" refX="4.5" viewBox="0 0 10 10" class="marker block" id="graph-3_block-pointStart"><path style="stroke-width: 1; stroke-dasharray: 1, 0;" class="arrowMarkerPath" d="M 0 5 L 10 10 L 10 0 z"></path></marker><marker orient="auto" markerHeight="11" markerWidth="11" markerUnits="userSpaceOnUse" refY="5" refX="11" viewBox="0 0 10 10" class="marker block" id="graph-3_block-circleEnd"><circle style="stroke-width: 1; stroke-dasharray: 1, 0;" class="arrowMarkerPath" r="5" cy="5" cx="5"></circle></marker><marker orient="auto" markerHeight="11" markerWidth="11" markerUnits="userSpaceOnUse" refY="5" refX="-1" viewBox="0 0 10 10" class="marker block" id="graph-3_block-circleStart"><circle style="stroke-width: 1; stroke-dasharray: 1, 0;" class="arrowMarkerPath" r="5" cy="5" cx="5"></circle></marker><marker orient="auto" markerHeight="11" markerWidth="11" markerUnits="userSpaceOnUse" refY="5.2" refX="12" viewBox="0 0 11 11" class="marker cross block" id="graph-3_block-crossEnd"><path style="stroke-width: 2; stroke-dasharray: 1, 0;" class="arrowMarkerPath" d="M 1,1 l 9,9 M 10,1 l -9,9"></path></marker><marker orient="auto" markerHeight="11" markerWidth="11" markerUnits="userSpaceOnUse" refY="5.2" refX="-1" viewBox="0 0 11 11" class="marker cross block" id="graph-3_block-crossStart"><path style="stroke-width: 2; stroke-dasharray: 1, 0;" class="arrowMarkerPath" d="M 1,1 l 9,9 M 10,1 l -9,9"></path></marker><g class="block"><g transform="translate(336.59374999999994, -168)" id="doc" class="node default default flowchart-label"><polygon style="" transform="translate(-40.078125,16)" class="label-container" points="-16,0 80.15625,0 80.15625,-32 -16,-32 0,-16"></polygon><g transform="translate(-36.078125, -12)" style="" class="label"><rect></rect><foreignObject height="24" width="72.15625"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel">Document</span></div></foreignObject></g></g><g transform="translate(336.59374999999994, -112)" id="down1" class="node default default flowchart-label"><polygon style="" transform="translate(-12,8)" class="label-container" points="12,0 0,-4 8,-4 8,-12 16,-12 16,-4 24,-4"></polygon><g transform="translate(0, 0)" style="" class="label"><rect></rect><foreignObject height="0" width="0"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel"> </span></div></foreignObject></g></g><g transform="translate(336.59374999999994, -56)" id="e" class="node default default flowchart-label"><rect height="48" width="673.1874999999999" y="-24" x="-336.59374999999994" ry="0" rx="0" style="" class="basic cluster composite label-container"></rect><g transform="translate(0, 0)" style="" class="label"><rect></rect><foreignObject height="0" width="0"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel"></span></div></foreignObject></g></g><g transform="translate(114.86458333333331, -56)" id="l" class="node default default flowchart-label"><rect height="32" width="213.72916666666663" y="-16" x="-106.86458333333331" ry="0" rx="0" style="" class="basic label-container"></rect><g transform="translate(-12.8515625, -12)" style="" class="label"><rect></rect><foreignObject height="24" width="25.703125"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel">left</span></div></foreignObject></g></g><g transform="translate(336.59374999999994, -56)" id="m" class="node default default flowchart-label"><rect height="32" width="213.72916666666663" y="-16" x="-106.86458333333331" ry="5" rx="5" style="fill:#d6d;stroke:#333;stroke-width:4px;" class="basic label-container"></rect><g transform="translate(-89.53125, -12)" style="" class="label"><rect></rect><foreignObject height="24" width="179.0625"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel">A wide one in the middle</span></div></foreignObject></g></g><g transform="translate(558.3229166666665, -56)" id="r" class="node default default flowchart-label"><rect height="32" width="213.72916666666663" y="-16" x="-106.86458333333331" ry="0" rx="0" style="" class="basic label-container"></rect><g transform="translate(-16.953125, -12)" style="" class="label"><rect></rect><foreignObject height="24" width="33.90625"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel">right</span></div></foreignObject></g></g><g transform="translate(336.59374999999994, 0)" id="down2" class="node default default flowchart-label"><polygon style="" transform="translate(-12,8)" class="label-container" points="12,0 0,-4 8,-4 8,-12 16,-12 16,-4 24,-4"></polygon><g transform="translate(0, 0)" style="" class="label"><rect></rect><foreignObject height="0" width="0"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel"> </span></div></foreignObject></g></g><g transform="translate(336.59374999999994, 56)" id="db" class="node default default flowchart-label"><path transform="translate(-13.4375,-22.6358024691358)" d="M 0,4.423868312757201 a 13.4375,4.423868312757201 0,0,0 26.875 0 a 13.4375,4.423868312757201 0,0,0 -26.875 0 l 0,36.4238683127572 a 13.4375,4.423868312757201 0,0,0 26.875 0 l 0,-36.4238683127572" style=""></path><g transform="translate(-9.4375, -12)" style="" class="label"><rect></rect><foreignObject height="24" width="18.875"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel">DB</span></div></foreignObject></g></g><g transform="translate(109.53124999999999, 168)" id="D" class="node default default flowchart-label"><rect height="48" width="219.06249999999997" y="-24" x="-109.53124999999999" ry="0" rx="0" style="" class="basic label-container"></rect><g transform="translate(-4.90625, -12)" style="" class="label"><rect></rect><foreignObject height="24" width="9.8125"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel">D</span></div></foreignObject></g></g><g transform="translate(563.6562499999999, 168)" id="C" class="node default default flowchart-label"><rect height="48" width="219.06249999999997" y="-24" x="-109.53124999999999" ry="0" rx="0" style="" class="basic label-container"></rect><g transform="translate(-4.7890625, -12)" style="" class="label"><rect></rect><foreignObject height="24" width="9.578125"><div style="display: inline-block; white-space: nowrap;" xmlns="http://www.w3.org/1999/xhtml"><span class="nodeLabel">C</span></div></foreignObject></g></g><path marker-end="url(#graph-3_block-pointEnd)" class="edge-thickness-normal edge-pattern-solid flowchart-link LS-a1 LE-b1" id="1-db-D" d="M323.156,62.628L306.474,70.857C289.792,79.085,256.427,95.543,229.53,108.81C202.633,122.077,182.204,132.154,171.989,137.192L161.775,142.231"></path><path marker-end="url(#graph-3_block-pointEnd)" class="edge-thickness-normal edge-pattern-solid flowchart-link LS-a1 LE-b1" id="1-C-db" d="M515,144L504.187,138.667C493.375,133.333,471.75,122.667,444.853,109.4C417.956,96.133,385.787,80.265,369.703,72.331L353.619,64.398"></path><path marker-end="url(#graph-3_block-pointEnd)" class="edge-thickness-normal edge-pattern-solid flowchart-link LS-a1 LE-b1" id="1-D-C" d="M219.063,168L238.651,168C258.24,168,297.417,168,335.927,168C374.437,168,412.281,168,431.203,168L450.125,168"></path></g></g></svg>
    //"""
    //        let svg = SVGKit()
    //        let res = try? svg.parse(data: data.data(using: .ascii)!)
    //
    //        let elements = res!.elements
    //        let e = elements[0] as! SVGGroup
    //
    //        for item in e.elements {
    //            if let path = item as? SVGPath {
    //                path.parse()
    //                print(path.d, path.pathData.toString())
    //            }
    //        }
    //    }

    @Test func pasePath() async throws {
        let parser = SVGPathParser()

        let cases: [(d: String, e: String)] = [
            (
                d: "M 10 10 H 90 V 90 H 10 Z",
                e: "[M 10.0 10.0, L 90.0 10.0, L 90.0 90.0, L 10.0 90.0, Z]"
            ),
            (
                d: "M 10 10 h 80 v 80 h -80 Z",
                e: "[M 10.0 10.0, L 90.0 10.0, L 90.0 90.0, L 10.0 90.0, Z]"
            ),
            (
                d: "M 70 110 C 70 140, 110 140, 110 110",
                e: "[M 70.0 110.0, C 70.0 140.0, 110.0 140.0, 110.0 110.0]"
            ),
            (
                d: "M 10 80 C 40 10, 65 10, 95 80 S 150 150, 180 80",
                e: "[M 10.0 80.0, C 40.0 10.0, 65.0 10.0, 95.0 80.0, C 125.0 150.0, 150.0 150.0, 180.0 80.0]"
            ),
            (
                d: "M 10 80 Q 95 10 180 80",
                e: "[M 10.0 80.0, Q 95.0 10.0, 180.0 80.0]"
            ),
            (
                d: "M 10 80 Q 52.5 10, 95 80 T 180 80",
                e: "[M 10.0 80.0, Q 52.5 10.0, 95.0 80.0, Q 137.5 150.0, 180.0 80.0]"
            ),
            (
                d: "M 10 80 Q 52.5 10, 95 80 T 180 80",
                e: "[M 10.0 80.0, Q 52.5 10.0, 95.0 80.0, Q 137.5 150.0, 180.0 80.0]"
            ),
            (
                d: "M 45 45 L 345 45 L 345 345 L 45 345 Z M 195 45 L 195 345 M 45 195 L 345 195",
                e:
                    "[M 45.0 45.0, L 345.0 45.0, L 345.0 345.0, L 45.0 345.0, Z, M 195.0 45.0, L 195.0 345.0, M 45.0 195.0, L 345.0 195.0]"
            ),
            (
                d: "M 250 100 A 45 45, 0, 1, 0, 295 145 L 295 100 Z",
                e: "[M 250.0 100.0, A 45.0 45.0 0.0 1 0 295.0 145.0, L 295.0 100.0, Z]"
            ),
        ]

        for item in cases {
            let res = parser.parse(d: item.d)
            #expect("\(res.segments)" == item.e)
        }
    }

    @Test func stringScanner() async throws {
        let v = "a123"
        let scanner = Scanner(string: v)
        print(scanner.scanCharacter())
        let d = scanner.scanDouble()
        print(d)
    }
}
