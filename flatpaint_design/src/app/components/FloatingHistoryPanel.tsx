import { Button } from "./ui/button";
import { GripVertical, X, RotateCcw } from "lucide-react";
import { ScrollArea } from "./ui/scroll-area";
import { useState } from "react";

interface FloatingHistoryPanelProps {
  onClose: () => void;
}

export function FloatingHistoryPanel({ onClose }: FloatingHistoryPanelProps) {
  const [position, setPosition] = useState({ x: window.innerWidth - 280, y: 100 });
  const [isDragging, setIsDragging] = useState(false);
  const [dragOffset, setDragOffset] = useState({ x: 0, y: 0 });

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

  return (
    <div
      className="fixed bg-white/95 backdrop-blur-xl rounded-xl shadow-2xl border border-zinc-300/50 overflow-hidden select-none w-64"
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
        <span className="text-xs font-medium text-zinc-600">History</span>
        <Button
          variant="ghost"
          size="icon"
          className="h-5 w-5 hover:bg-zinc-200 rounded"
          onClick={onClose}
        >
          <X className="w-3 h-3 text-zinc-500" />
        </Button>
      </div>

      {/* History Content */}
      <div className="p-3">
        <div className="flex gap-2 mb-2">
          <Button 
            variant="outline" 
            size="sm" 
            className="flex-1 h-8 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
          >
            <RotateCcw className="w-3 h-3 mr-1" />
            Undo
          </Button>
          <Button 
            variant="outline" 
            size="sm" 
            className="flex-1 h-8 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
          >
            <RotateCcw className="w-3 h-3 mr-1 scale-x-[-1]" />
            Redo
          </Button>
        </div>
        <div className="h-48 bg-white border border-zinc-300 rounded-lg">
          <ScrollArea className="h-full p-2">
            <div className="space-y-1">
              <div className="text-xs text-zinc-500 py-1 px-2 hover:bg-zinc-100 rounded cursor-pointer">
                Undo: —
              </div>
              <div className="text-xs text-zinc-500 py-1 px-2 hover:bg-zinc-100 rounded cursor-pointer">
                Redo: —
              </div>
              <div className="text-xs text-zinc-700 py-1 px-2 bg-blue-100 rounded border border-blue-300">
                0: (initial)
              </div>
            </div>
          </ScrollArea>
        </div>
      </div>
    </div>
  );
}