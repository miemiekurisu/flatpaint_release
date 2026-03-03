import { Tabs, TabsContent, TabsList, TabsTrigger } from "./ui/tabs";
import { Slider } from "./ui/slider";
import { Label } from "./ui/label";
import { Input } from "./ui/input";
import { 
  Eye, 
  EyeOff, 
  Lock, 
  Unlock, 
  Trash2,
  Plus,
  Copy,
  Minus,
  ChevronDown,
  Image as ImageIcon,
  Type,
  Square,
  RotateCcw,
  Settings
} from "lucide-react";
import { Button } from "./ui/button";
import { ScrollArea } from "./ui/scroll-area";

export function PropertiesPanel() {
  return (
    <div className="w-64 bg-zinc-50 border-l border-zinc-300 flex flex-col">
      {/* History Panel */}
      <div className="border-b border-zinc-300">
        <div className="h-10 flex items-center justify-between px-3 bg-zinc-100">
          <span className="text-sm font-medium text-zinc-700">History</span>
        </div>
        <div className="p-3 space-y-2">
          <div className="flex gap-2">
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
          <div className="h-32 bg-white border border-zinc-300 rounded-lg p-2">
            <ScrollArea className="h-full">
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

      {/* Layers Panel */}
      <div className="flex-1 flex flex-col">
        <div className="h-10 flex items-center justify-between px-3 bg-zinc-100 border-b border-zinc-300">
          <span className="text-sm font-medium text-zinc-700">Layers</span>
        </div>

        <div className="p-3 flex flex-col flex-1">
          {/* Layer Controls */}
          <div className="flex gap-1 mb-2">
            <Button 
              variant="outline" 
              size="icon" 
              className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
            >
              <Plus className="w-3.5 h-3.5" />
            </Button>
            <Button 
              variant="outline" 
              size="icon" 
              className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
            >
              <Minus className="w-3.5 h-3.5" />
            </Button>
            <Button 
              variant="outline" 
              size="icon" 
              className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
            >
              <Copy className="w-3.5 h-3.5" />
            </Button>
            <Button 
              variant="outline" 
              size="icon" 
              className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
            >
              <ChevronDown className="w-3.5 h-3.5" />
            </Button>
            <Button 
              variant="outline" 
              size="icon" 
              className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
            >
              <Settings className="w-3.5 h-3.5" />
            </Button>
            <Button 
              variant="outline" 
              size="icon" 
              className="h-7 w-7 border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700"
            >
              <Trash2 className="w-3.5 h-3.5" />
            </Button>
          </div>

          {/* Blend Mode and Opacity */}
          <div className="mb-3 space-y-2">
            <div className="flex items-center gap-2">
              <Button 
                variant="outline" 
                size="sm" 
                className="flex-1 h-7 px-2 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700 justify-between"
              >
                Caps
                <ChevronDown className="w-3 h-3 ml-1" />
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                className="flex-1 h-7 px-2 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700 justify-between"
              >
                Flat
                <ChevronDown className="w-3 h-3 ml-1" />
              </Button>
            </div>
            <div className="flex items-center gap-2">
              <Button 
                variant="outline" 
                size="sm" 
                className="flex-1 h-7 px-2 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700 justify-between"
              >
                Name
                <ChevronDown className="w-3 h-3 ml-1" />
              </Button>
              <Button 
                variant="outline" 
                size="sm" 
                className="flex-1 h-7 px-2 text-xs border-zinc-300 bg-white hover:bg-zinc-100 text-zinc-700 justify-between"
              >
                Props
                <ChevronDown className="w-3 h-3 ml-1" />
              </Button>
            </div>
            <div className="flex items-center gap-2 bg-white border border-zinc-300 rounded-lg p-2">
              <span className="text-xs text-zinc-600">Normal</span>
              <ChevronDown className="w-3 h-3 ml-auto text-zinc-500" />
            </div>
          </div>

          {/* Layers List */}
          <ScrollArea className="flex-1 mb-3">
            <div className="space-y-1">
              <LayerItem 
                name="Background" 
                visible={true}
                locked={false}
                selected
              />
            </div>
          </ScrollArea>

          {/* Layer Thumbnail */}
          <div className="bg-white border border-zinc-300 rounded-lg p-2 h-32 flex items-center justify-center">
            <div className="w-full h-full bg-[linear-gradient(45deg,#ccc_25%,transparent_25%,transparent_75%,#ccc_75%,#ccc),linear-gradient(45deg,#ccc_25%,transparent_25%,transparent_75%,#ccc_75%,#ccc)] bg-[length:20px_20px] bg-[position:0_0,10px_10px]" />
          </div>
        </div>
      </div>
    </div>
  );
}

function LayerItem({ 
  name, 
  visible, 
  locked, 
  selected = false 
}: { 
  name: string; 
  visible: boolean; 
  locked: boolean; 
  selected?: boolean;
}) {
  return (
    <div 
      className={`flex items-center gap-2 px-2 py-1.5 rounded-lg cursor-pointer group ${
        selected 
          ? "bg-blue-500 text-white" 
          : "bg-white hover:bg-zinc-100 text-zinc-700 border border-zinc-300"
      }`}
    >
      <Eye className="w-3.5 h-3.5" />
      <span className="text-xs flex-1 truncate">{name}</span>
    </div>
  );
}