//
//  LatexSampleView.swift
//  PicSolve
//
//  Created by Adriano Oliviero on 07/11/25.
//

import SwiftUI
import LaTeXSwiftUI

struct LatexSampleView: View {
    var body: some View {
        LaTeX("$$\\displaystyle\\iint\\limits_D U(x,y)+V(x,y)dxdy=$$ $$\\int_{+\\partial D}\\frac{\\partial}{\\partial x}U(x,y)dy+\\frac{\\partial}{\\partial y}V(x,y)dx$$")
    }
}

#Preview {
    LatexSampleView()
}
