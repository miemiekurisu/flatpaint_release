import { Button } from "./ui/button";
import { GripVertical, X } from "lucide-react";
import { useState } from "react";

interface FloatingColorPanelProps {
  onClose: () => void;
}

export function FloatingColorPanel({ onClose }: FloatingColorPanelProps) {
  const [position, setPosition] = useState({ x: 20, y: 380 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });
  const [primaryColor, setPrimaryColor] = useState("#000000");
  const [secondaryColor, setSecondaryColor] = useState("#FFFFFF");

  const handleMouseDown = (e: React.MouseEvent) => {
    if ((e.target as HTMLElement).closest('.drag-handle')) {
      setIsDragging(true);
      setDragOffset({
        x: e.clientX - position.x,
        y: e.clientY - position.y,
      });
    }
  };

  const handleMouseMove = (e: MouseEvent) => {
    if (isDragging) {
      setPosition({
        x: e.clientX - dragOffset.x,
        y: e.clientY - dragOffset.y,
      });
    }
  };

  const handleMouseUp = () => {
    setIsDragging(false);
  };

  useState(() => {
    if (isDragging) {
      window.addEventListener('mousemove', handleMouseMove);
      window.addEventListener('mouseup', handleMouseUp);
      return () => {
        window.removeEventListener('mousemove', handleMouseMove);
        window.removeEventListener('mouseup', handleMouseUp);
      };
    }
  });

  // Generate color wheel colors
  const generateColorWheel = () => {
    const colors = [];
    const segments = 12;
    for (let i = 0; i < segments; i++) {
      const hue = (i * 360) / segments;
      colors.push(`hsl(${hue}, 100%, 50%)`);
    }
    return colors;
  };

  return (
    <div
      className="fixed bg-white/95 backdrop-blur-xl rounded-xl shadow-2xl border border-zinc-300/50 overflow-hidden select-none w-52"
      style={{
        left: `${position.x}px`,
        top: `${position.y}px`,
        zIndex: 50,
      }}
      onMouseDown={handleMouseDown}
    >
      {/* Title Bar */}
      <div className="h-8 bg-gradient-to-b from-zinc-100 to-zinc-50 border-b border-zinc-200 flex items-center justify-between px-3 drag-handle cursor-move">
        <GripVertical className="w-3 h-3 text-zinc-400" />
        <span className="text-xs font-medium text-zinc-600">Colors</span>
        <Button
          variant="ghost"
          size="icon"
          className="h-5 w-5 hover:bg-zinc-200 rounded"
          onClick={onClose}
        >
          <X className="w-3 h-3 text-zinc-500" />
        </Button>
      </div>

      {/* Colors Content */}
      <div className="p-3">
        {/* Primary and Secondary Colors */}
        <div className="flex items-center justify-between mb-3">
          <div className="flex items-center gap-2">
            <div className="relative w-12 h-12">
              <div 
                className="absolute top-0 left-0 w-9 h-9 border-2 border-white rounded-lg shadow-md cursor-pointer"
                style={{ backgroundColor: primaryColor }}
                onClick={() => document.getElementById('float-primary-color')?.click()}
              />
              <div 
                className="absolute bottom-0 right-0 w-9 h-9 border-2 border-zinc-400 rounded-lg shadow-md cursor-pointer bg-white"
                style={{ backgroundColor: secondaryColor }}
                onClick={() => document.getElementById('float-secondary-color')?.click()}
              />
              <input 
                id="float-primary-color" 
                type="color" 
                value={primaryColor}
                onChange={(e) => setPrimaryColor(e.target.value)}
                className="hidden"
              />
              <input 
                id="float-secondary-color" 
                type="color" 
                value={secondaryColor}
                onChange={(e) => setSecondaryColor(e.target.value)}
                className="hidden"
              />
            </div>
          </div>
          
          <Button 
            variant="outline" 
            size="sm" 
            className="h-7 px-2 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
            onClick={() => {
              const temp = primaryColor;
              setPrimaryColor(secondaryColor);
              setSecondaryColor(temp);
            }}
          >
            Swap
          </Button>
        </div>

        {/* RGB Values */}
        <div className="space-y-2 mb-3">
          <div className="flex items-center gap-2">
            <span className="text-xs text-zinc-600 w-4">R:</span>
            <input 
              type="number" 
              defaultValue="0"
              min="0"
              max="255"
              className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-zinc-600 w-4">G:</span>
            <input 
              type="number" 
              defaultValue="0"
              min="0"
              max="255"
              className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
          <div className="flex items-center gap-2">
            <span className="text-xs text-zinc-600 w-4">B:</span>
            <input 
              type="number" 
              defaultValue="0"
              min="0"
              max="255"
              className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500"
            />
          </div>
        </div>

        {/* Hex Value */}
        <div className="flex items-center gap-2 mb-3">
          <span className="text-xs text-zinc-600 w-4">#:</span>
          <input 
            type="text" 
            value={primaryColor.replace('#', '')}
            onChange={(e) => setPrimaryColor('#' + e.target.value)}
            className="flex-1 h-6 px-2 text-xs bg-white border border-zinc-300 rounded text-zinc-700 focus:outline-none focus:ring-2 focus:ring-blue-500 uppercase"
            maxLength={6}
          />
        </div>

        {/* Color Picker - Interactive Circular Palette */}
        <div className="relative w-40 h-40 mx-auto mb-3">
          {/* Outer ring - Saturated colors */}
          <svg className="w-full h-full" viewBox="0 0 160 160">
            <defs>
              <linearGradient id="colorGradient" x1="0%" y1="0%" x2="100%" y2="0%">
                <stop offset="0%" stopColor="#ff0000" />
                <stop offset="16.67%" stopColor="#ffff00" />
                <stop offset="33.33%" stopColor="#00ff00" />
                <stop offset="50%" stopColor="#00ffff" />
                <stop offset="66.67%" stopColor="#0000ff" />
                <stop offset="83.33%" stopColor="#ff00ff" />
                <stop offset="100%" stopColor="#ff0000" />
              </linearGradient>
            </defs>
            
            {/* Color wheel segments */}
            {Array.from({ length: 36 }).map((_, i) => {
              const angle = (i * 360) / 36;
              const nextAngle = ((i + 1) * 360) / 36;
              const hue = angle;
              
              // Outer arc
              const startX = 80 + 70 * Math.cos((angle - 90) * Math.PI / 180);
              const startY = 80 + 70 * Math.sin((angle - 90) * Math.PI / 180);
              const endX = 80 + 70 * Math.cos((nextAngle - 90) * Math.PI / 180);
              const endY = 80 + 70 * Math.sin((nextAngle - 90) * Math.PI / 180);
              
              // Inner arc
              const innerStartX = 80 + 40 * Math.cos((angle - 90) * Math.PI / 180);
              const innerStartY = 80 + 40 * Math.sin((angle - 90) * Math.PI / 180);
              const innerEndX = 80 + 40 * Math.cos((nextAngle - 90) * Math.PI / 180);
              const innerEndY = 80 + 40 * Math.sin((nextAngle - 90) * Math.PI / 180);
              
              return (
                <path
                  key={i}
                  d={`M ${startX} ${startY} A 70 70 0 0 1 ${endX} ${endY} L ${innerEndX} ${innerEndY} A 40 40 0 0 0 ${innerStartX} ${innerStartY} Z`}
                  fill={`hsl(${hue}, 100%, 50%)`}
                  className="cursor-pointer hover:opacity-80 transition-opacity"
                  onClick={() => setPrimaryColor(`hsl(${hue}, 100%, 50%)`)}
                />
              );
            })}
            
            {/* Center circle - Grayscale */}
            <circle cx="80" cy="80" r="35" fill="url(#grayGradient)" className="cursor-pointer" onClick={() => setPrimaryColor('#808080')} />
            <defs>
              <radialGradient id="grayGradient">
                <stop offset="0%" stopColor="#ffffff" />
                <stop offset="100%" stopColor="#000000" />
              </radialGradient>
            </defs>
          </svg>
        </div>

        {/* Quick Color Palette */}
        <div className="grid grid-cols-10 gap-1">
          {[
            '#000000', '#1a1a1a', '#333333', '#4d4d4d', '#666666',
            '#808080', '#999999', '#b3b3b3', '#cccccc', '#e6e6e6',
            '#ffffff', '#ff0000', '#ff8800', '#ffff00', '#88ff00',
            '#00ff00', '#00ff88', '#00ffff', '#0088ff', '#0000ff',
            '#8800ff', '#ff00ff', '#ff0088', '#8b4513', '#a0522d',
            '#cd853f', '#deb887', '#f4a460', '#d2691e', '#bc8f8f',
          ].map((color, i) => (
            <button
              key={i}
              className="w-4 h-4 rounded border border-zinc-300 hover:scale-125 transition-transform cursor-pointer"
              style={{ backgroundColor: color }}
              onClick={() => setPrimaryColor(color)}
            />
          ))}
        </div>
      </div>
    </div>
  );
}