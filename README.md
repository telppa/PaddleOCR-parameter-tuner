# PaddleOCR-parameter-tuner  
PaddleOCR 参数调优器  
  <br>
# 简介  
虽然在默认设置下 PaddleOCR 已有较好的识别效果。  
但在诸如游戏截图、PDF文档、手写文稿等不同场景中，因为字形背景等差异因素的影响，同一套参数很难完美适应不同场景。  
因此，可通过本程序可视化调节 PaddleOCR 参数，直观的比较不同参数的识别效果，进而择优选择，并最终导出可运行代码。  
这样我们就能为每个单独场景设置最佳参数，获得最佳识别效果。  
  <br>
# 下载  
**[点击此处]()**  
  <br>
# 用法  
调节参数并观察识别效果。  
觉得当前效果完美了，则选择 “导出当前效果” 。  
觉得当前效果还不错，但又想再继续调节试试，则选择 “存为候选” 。  
![效果图](https://raw.githubusercontent.com/telppa/PaddleOCR-parameter-tuner/main/Img/5.png)  
  <br>
“放大查看” 可以放大比较 “当前效果” 与 “候选效果” 。  
![效果图](https://raw.githubusercontent.com/telppa/PaddleOCR-parameter-tuner/main/Img/6.png)  
  <br>
“导出xx效果” 将生成类似 “效果1.ahk“ “效果1.png” “效果1.txt” 的文件。  
其中 ”效果1.ahk“ 是代码文件，将其拖拽至 参数调优器.exe 上即可运行。  
而 “效果1.png” “效果1.txt” 则是对应代码的效果，主要作用是便于记忆。  
![效果图](https://raw.githubusercontent.com/telppa/PaddleOCR-parameter-tuner/main/Img/7.png)  
  <br>
# 相关项目  
#### PaddleOCR-AutoHotkey  
* https://github.com/telppa/PaddleOCR-AutoHotkey  
