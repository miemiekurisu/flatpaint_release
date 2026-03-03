import { useRef, useEffect, useState } from "react";

export function CanvasArea() {
  const canvasRef = useRef<HTMLCanvasElement>(null);
  const [isDragging, setIsDragging] = useState(false);
  const [dragStart, setDragStart] = useState({ x: 0, y: 0 });

  useEffect(() => {
    const canvas = canvasRef.current;
    if (!canvas) return;

    const ctx = canvas.getContext("2d");
    if (!ctx) return;

    // Set canvas size
    canvas.width = 1024;
    canvas.height = 768;

    // Draw checkerboard background (transparency indicator)
    const tileSize = 16;
    for (let y = 0; y < canvas.height; y += tileSize) {
      for (let x = 0; x < canvas.width; x += tileSize) {
        ctx.fillStyle = (x / tileSize + y / tileSize) % 2 === 0 ? '#ffffff' : '#e5e5e5';
        ctx.fillRect(x, y, tileSize, tileSize);
      }
    }

  }, []);

  const handleMouseDown = (e: React.MouseEvent<HTMLCanvasElement>) => {
    setIsDragging(true);
    setDragStart({ x: e.clientX, y: e.clientY });
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  const handleMouseMove = (e: React.MouseEvent<HTMLCanvasElement>) => {
    if (!isDragging) return;
    // Handle dragging logic here
  };

  return (
    <div className="flex-1 bg-zinc-200 flex items-center justify-center overflow-auto p-8 relative">
      {/* Ruler - Top */}
      <div className="absolute top-0 left-0 right-0 h-6 bg-white border-b border-zinc-300 flex">
        {Array.from({ length: 40 }).map((_, i) => (
          <div 
            key={i} 
            className="flex-1 border-l border-zinc-300 relative"
          >
            {i % 5 === 0 && (
              <span className="absolute top-0.5 left-1 text-[9px] text-zinc-500">
                {i * 50}
              </span>
            )}
            {i % 5 !== 0 && (
              <div className="w-px h-2 bg-zinc-400 absolute left-0 top-0" />
            )}
          </div>
        ))}
      </div>

      {/* Ruler - Left */}
      <div className="absolute top-6 left-0 bottom-0 w-6 bg-white border-r border-zinc-300">
        {Array.from({ length: 30 }).map((_, i) => (
          <div 
            key={i} 
            className="border-t border-zinc-300 relative"
            style={{ height: '25.6px' }}
          >
            {i % 5 === 0 && (
              <span className="absolute left-0.5 text-[9px] text-zinc-500 writing-mode-vertical">
                {i * 50}
              </span>
            )}
          </div>
        ))}
      </div>

      {/* Main Canvas Container */}
      <div className="relative ml-6 mt-6">
        <canvas
          ref={canvasRef}
          className="shadow-lg cursor-crosshair"
          onMouseDown={handleMouseDown}
          onMouseUp={handleMouseUp}
          onMouseMove={handleMouseMove}
          onMouseLeave={handleMouseUp}
        />
      </div>

      {/* Status Bar */}
      <div className="absolute bottom-0 left-0 right-0 h-6 bg-zinc-100 border-t border-zinc-300 flex items-center px-3 text-xs text-zinc-600">
        <span className="mr-4">Brush — Brush paints with the primary or secondary color</span>
        <span className="mr-4">Image: 1024 x 768 px</span>
        <div className="ml-auto flex items-center gap-4">
          <span>Selection: none</span>
          <span>Cursor: 561, 207 px</span>
          <span>Layer: 1/1</span>
          <span>Units: px</span>
        </div>
      </div>
    </div>
  );
}