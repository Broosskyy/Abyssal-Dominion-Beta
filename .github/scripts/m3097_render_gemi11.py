#!/usr/bin/env python3
"""Render true eight direction fallback thumbnails from the user GLB (M3097).
Runs with a virtual X display on GitHub Actions; model source is never modified.
"""
import argparse
import math
from pathlib import Path
import numpy as np
import trimesh
import vtk
from vtk.util.numpy_support import numpy_to_vtk, numpy_to_vtkIdTypeArray, vtk_to_numpy
from PIL import Image

def render(src: Path, dest: Path) -> None:
    dest.mkdir(parents=True, exist_ok=True)
    scene = trimesh.load(src, force="scene")
    app = vtk.vtkAppendPolyData()
    for node in scene.graph.nodes_geometry:
        transformation, geom_name = scene.graph[node]
        mesh = scene.geometry[geom_name].copy()
        mesh.apply_transform(transformation)
        poly = vtk.vtkPolyData()
        points = vtk.vtkPoints()
        points.SetData(numpy_to_vtk(mesh.vertices.astype("float32")))
        poly.SetPoints(points)
        faces = np.hstack((np.full((len(mesh.faces), 1), 3), mesh.faces)).astype("int64")
        cells = vtk.vtkCellArray()
        cells.SetCells(len(faces), numpy_to_vtkIdTypeArray(faces.ravel(), deep=True))
        poly.SetPolys(cells)
        colors = np.asarray(mesh.visual.to_color().vertex_colors[:, :3], dtype=np.uint8)
        rgb = numpy_to_vtk(colors, deep=True, array_type=vtk.VTK_UNSIGNED_CHAR)
        rgb.SetName("RGB")
        poly.GetPointData().SetScalars(rgb)
        app.AddInputData(poly)
    app.Update()
    mapper = vtk.vtkPolyDataMapper()
    mapper.SetInputConnection(app.GetOutputPort())
    mapper.SetScalarModeToUsePointData()
    mapper.ScalarVisibilityOn()
    actor = vtk.vtkActor()
    actor.SetMapper(mapper)
    renderer = vtk.vtkRenderer()
    renderer.AddActor(actor)
    renderer.SetBackground(0, 0, 0)
    renderer.SetBackgroundAlpha(0.0)
    renderer.SetUseDepthPeeling(False)
    window = vtk.vtkRenderWindow()
    window.SetOffScreenRendering(1)
    window.AddRenderer(renderer)
    window.SetSize(640, 640)
    window.SetAlphaBitPlanes(1)
    window.SetMultiSamples(0)
    camera = renderer.GetActiveCamera()
    center = scene.bounds.mean(axis=0)
    camera.SetFocalPoint(*center)
    camera.SetViewUp(0, 1, 0)
    camera.ParallelProjectionOn()
    camera.SetParallelScale(30)
    renderer.SetAmbient((0.8, 0.8, 0.8))
    light = vtk.vtkLight()
    light.SetPosition(100, 120, 70)
    light.SetFocalPoint(*center)
    light.SetIntensity(1.25)
    renderer.AddLight(light)
    frames = []
    for i in range(8):
        angle = math.pi / 4 + 2 * math.pi * i / 8
        camera.SetPosition(center[0] + math.sin(angle) * 75, center[1] + 65, center[2] + math.cos(angle) * 75)
        camera.SetViewUp(0, 1, 0)
        renderer.ResetCameraClippingRange()
        window.Render()
        grab = vtk.vtkWindowToImageFilter()
        grab.SetInput(window)
        grab.SetInputBufferTypeToRGBA()
        grab.ReadFrontBufferOff()
        grab.Update()
        rgba = vtk_to_numpy(grab.GetOutput().GetPointData().GetScalars()).reshape(640, 640, 4)[::-1].copy()
        image = Image.fromarray(rgba, "RGBA")
        bbox = image.getbbox()
        if bbox is None:
            raise RuntimeError(f"Empty source render for frame {i}")
        crop = image.crop(bbox)
        crop.thumbnail((278, 278), Image.Resampling.LANCZOS)
        tile = Image.new("RGBA", (320, 320))
        tile.alpha_composite(crop, ((320 - crop.width) // 2, (320 - crop.height) // 2))
        frames.append(tile)
        if i == 0:
            preview = Image.new("RGBA", (640, 640))
            large = image.crop(bbox)
            large.thumbnail((530, 530), Image.Resampling.LANCZOS)
            preview.alpha_composite(large, ((640 - large.width) // 2, (640 - large.height) // 2))
            preview.save(dest / "gemi11_uv_preview.png", optimize=True)
    atlas = Image.new("RGBA", (2560, 320))
    for i, tile in enumerate(frames):
        atlas.alpha_composite(tile, (i * 320, 0))
    atlas.save(dest / "gemi11_uv_eight.png", optimize=True)
    assert (dest / "gemi11_uv_preview.png").stat().st_size > 1000
    assert (dest / "gemi11_uv_eight.png").stat().st_size > 1000
    print("M3097: rendered eight 320px views and one 640px preview from original Gemi11 GLB")

if __name__ == "__main__":
    parser = argparse.ArgumentParser()
    parser.add_argument("source", type=Path)
    parser.add_argument("output_dir", type=Path)
    args = parser.parse_args()
    render(args.source, args.output_dir)
