/*
2022.11.06
  去掉托盘图标。
  更改导出提示。
  耗时计算更加准确。
  图片显示不会超出图片框。
  版本号 1.4.6
*/
#NoEnv
#NoTrayIcon
#SingleInstance Force

界面:
  Gui -DPIScale
  guiFontSize := Round(GuiDefaultFont().Size/(A_ScreenDPI/96))
  Gui Font, s%guiFontSize%, 微软雅黑
  
  ; 这就是1张普通的纯白图片而已
  初始图片 := ImagePutHBitmap("iVBORw0KGgoAAAANSUhEUgAAAQ8AAAEOAQMAAACtvQDYAAAAA1BMVEX///+nxBvIAAAAIElEQVRo3u3BMQEAAADCIPuntsYOYAAAAAAAAAAAAHkHJOoAAbm5cMUAAAAASUVORK5CYII=")
  Gui Add, GroupBox, x8 y8 w610 h300, 当前效果
  Gui Add, Picture, x24 y32 w270 h260 vpic1 AltSubmit, HBITMAP:*%初始图片%  ; 避免被自动释放
  Gui Add, Edit, x328 y32 w270 h260 vedit1, 1. “载入图片”`n2. “开始识别”`n3. “导出效果”
  
  Gui Add, GroupBox, x632 y8 w300 h300, 候选效果
  Gui Add, Picture, x648 y32 w270 h260 vpic2 AltSubmit, HBITMAP:*%初始图片%  ; 避免被自动释放，留着给识别器初始化用
  
  Gui Add, GroupBox, x8 y320 w924 h300, 参数调节
  Gui Add, CheckBox, x24 y344 w120 h23 vfast_model, fast model
  Gui Add, CheckBox, x24 y376 w120 h23 vuse_mkldnn, use_mkldnn
  Gui Add, Edit, x24 y408 w120 h21 vcpu_math_library_num_threads Hwndhcpu_math_library_num_threads
  Edit_SetCueBanner(hcpu_math_library_num_threads, "cpu_math_library_num_threads", True)
  
  Gui Add, CheckBox, x168 y344 w120 h23 +Disabled, use_gpu
  Gui Add, Edit, x168 y376 w120 h21 +Disabled, gpu_id
  Gui Add, Edit, x168 y408 w120 h21 +Disabled, gpu_mem
  
  Gui Add, CheckBox, x24 y448 w120 h23 vuse_polygon_score +Checked, use_polygon
  Gui Add, Edit, x24 y480 w120 h21 vmax_side_len Hwndhmax_side_len
  Gui Add, Edit, x24 y512 w120 h21 vdet_db_thresh Hwndhdet_db_thresh
  Gui Add, Edit, x24 y544 w120 h21 vdet_db_box_thresh Hwndhdet_db_box_thresh
  Gui Add, Edit, x24 y576 w120 h21 vdet_db_unclip_ratio Hwndhdet_db_unclip_ratio
  Edit_SetCueBanner(hmax_side_len, "max_side_len", True)
  Edit_SetCueBanner(hdet_db_thresh, "det_db_thresh", True)
  Edit_SetCueBanner(hdet_db_box_thresh, "det_db_box_thresh", True)
  Edit_SetCueBanner(hdet_db_unclip_ratio, "det_db_unclip_ratio", True)
  
  Gui Add, CheckBox, x168 y448 w120 h23 vuse_angle_cls, use_angle_cls
  Gui Add, Edit, x168 y480 w120 h21 vcls_thresh Hwndhcls_thresh
  Edit_SetCueBanner(hcls_thresh, "cls_thresh", True)
  
  Gui Add, CheckBox, x168 y544 w120 h23 vuse_tensorrt, use_tensorrt
  Gui Add, CheckBox, x168 y576 w120 h23 vuse_fp16, use_fp16
  
  Gui Add, Button, x328 y374 w270 h50 v载入图片, 载入图片
  Gui Add, Button, x648 y374 w270 h50 v开始识别 +Disabled, 开始识别
  Gui Add, Button, x328 y450 w270 h50 v放大查看 +Disabled, 放大查看
  Gui Add, Button, x648 y450 w270 h50 v存为候选 +Disabled, 存为候选
  Gui Add, Button, x328 y526 w270 h50 v导出当前效果 +Disabled, 导出当前效果
  Gui Add, Button, x648 y526 w270 h50 v导出候选效果 +Disabled, 导出候选效果
  
  GuiControl, Focus, 载入图片
  Gui Show, w940 h630, PaddleOCR 参数调优器 ver. 1.4.6
  
  OnMessage(0x6, "WM_ACTIVATE")     ; 监视窗口是否激活
  OnMessage(0x200, "WM_MouseMove")  ; 监视鼠标移动消息
  
return

Button载入图片:
  Gui +OwnDialogs
  FileSelectFile, chooseFile, 3, , 选择待识别图片, 图片 (*.bmp; *.png; *.tif; *.tiff; *.jpg; *.jpeg; *.gif; *.dib; *.rle; *.jpe; *.jfif)
  if (chooseFile)
  {
    buf := ImagePutBuffer(chooseFile)  ; buf 变量清空时会自动释放资源
    ratio := buf.width / buf.height
    
    if (ratio>=1)
      GuiControl, , pic1, *w270 *h-1 %chooseFile%
    else
      GuiControl, , pic1, *w-1 *h260 %chooseFile%
    
    pic1Path := chooseFile
    
    GuiControl, Enable, 开始识别
    GuiControl, Enable, 放大查看
  }
return

Button开始识别:
  Gui, Submit, NoHide
  
  if (!FileExist(chooseFile))
  {
    Gui +OwnDialogs
    MsgBox 0x10, , 载入的图片已丢失，请重新载入图片！
    return
  }
  
  当前参数 := { model:                        fast_model=1 ? "fast" : "server"
              , get_all_info:                 0
              , cpu_math_library_num_threads: cpu_math_library_num_threads
              , use_mkldnn:                   use_mkldnn
              , max_side_len:                 max_side_len
              , det_db_thresh:                det_db_thresh
              , det_db_box_thresh:            det_db_box_thresh
              , det_db_unclip_ratio:          det_db_unclip_ratio
              , use_polygon_score:            use_polygon_score
              , use_angle_cls:                use_angle_cls
              , cls_thresh:                   cls_thresh
              , visualize:                    1
              , use_tensorrt:                 use_tensorrt
              , use_fp16:                     use_fp16}
  
  ; 将当前参数文本化
  当前参数文本 := ""
  for k, v in 当前参数
    当前参数文本 .= k v "`n"
  
  ; 任何参数改变都会导致模型初始化，因此计算耗时应该排除初始化所用时间
  loop 2
  {
    if (pre_当前参数文本 = 当前参数文本)
    {
      GuiControl, , edit1, 识别中...
      Sleep 50  ; 这里必须有个延时，否则速度太快会导致文字提示显示不出来
      startTime        := A_TickCount
      当前识别结果     := PaddleOCR(chooseFile, 当前参数)
      break
    }
    else
    {
      GuiControl, , edit1, 初始化中...
      Sleep 50
      pre_当前参数文本 := 当前参数文本
      当前识别结果     := PaddleOCR(初始图片, 当前参数)
    }
  }
  GuiControl, , edit1, % "耗时 " A_TickCount-startTime " ms`n--------`n" 当前识别结果
  
  ; 识别成功
  if (FileExist("ocr_vis.png"))
  {
    if (ratio>=1)
      GuiControl, , pic1, *w270 *h-1 ocr_vis.png
    else
      GuiControl, , pic1, *w-1 *h260 ocr_vis.png
    
    pic1Path   := "ocr_vis.png"
    
    GuiControl, Enable, 导出当前效果
    GuiControl, Enable, 存为候选
  }
  else
  {
    Gui +OwnDialogs
    MsgBox 0x30, , 识别过程似乎出现了某种错误！`n`n最大可能就是缺少 vc2015-2017 x64 运行时库，或 CPU 太老。
  }
return

Button放大查看:
  if      (FileExist(pic2Path))
  {
    ; 转换为整数
    halfW := Format("{:d}", A_ScreenWidth//2 - 33)
    ; 两张图左、中、右的间距都是22像素
    ImagePutWindow({image:pic1Path, scale:[halfW, ""]}, "当前效果", [22, 40])
    ImagePutWindow({image:pic2Path, scale:[halfW, ""]}, "候选效果", [halfW+44, 40])
  }
  else if (FileExist(pic1Path))
  {
    ; 转换为整数
    halfW := Format("{:d}", A_ScreenWidth - 44)
    ; 图左、右的间距都是22像素
    ImagePutWindow({image:pic1Path, scale:[halfW, ""]}, "当前效果", [22, 40])
  }
return

Button存为候选:
  if (FileExist(pic1Path))
  {
    候选参数     := 当前参数.Clone()
    候选识别结果 := 当前识别结果
    FileCopy, %pic1Path%, ocr_vis2.png, 1
    
    if (ratio>=1)
      GuiControl, , pic2, *w270 *h-1 ocr_vis2.png
    else
      GuiControl, , pic2, *w-1 *h260 ocr_vis2.png
    
    pic2Path     := "ocr_vis2.png"
    
    GuiControl, Enable, 导出候选效果
  }
return

Button导出当前效果:
Button导出候选效果:
  目标图片     := A_ThisLabel="Button导出当前效果" ? "ocr_vis.png" : "ocr_vis2.png"
  目标参数     := A_ThisLabel="Button导出当前效果" ? 当前参数      : 候选参数
  目标识别结果 := A_ThisLabel="Button导出当前效果" ? 当前识别结果  : 候选识别结果
  
  if (FileExist(目标图片))
  {
    ; 为文件取得不重名的编号
    loop, 500
      if (!FileExist("效果" A_Index ".png"))
      {
        效果编号 := A_Index
        break
      }
    
    ; 效果n.png
    FileCopy, %目标图片%, 效果%效果编号%.png, 1
    
    ; 效果n.txt
    FileDelete, 效果%效果编号%.txt
    FileAppend, %目标识别结果%, 效果%效果编号%.txt, UTF-8
    
    导出参数 := ""
    for k, v in 目标参数
      if (v!="" and k!="visualize" and k!="get_all_info")
        导出参数 .= k ":""" v """, "
    
    导出文本 := "图片 := """ chooseFile """`r`n"
    导出文本 .= "参数 := {" SubStr(导出参数, 1, -2) "}`r`n"
    导出文本 .= "MsgBox, % PaddleOCR(图片, 参数)`r`n`r`n"
    导出文本 .= "#Include %A_LineFile%\..\PaddleOCR\PaddleOCR.ahk"
    
    FileDelete, 效果%效果编号%.ahk
    FileAppend, %导出文本%, 效果%效果编号%.ahk, UTF-8
    
    Gui +OwnDialogs
    MsgBox 0x40, , “效果%效果编号%.ahk” 导出成功！
    
    Run, explorer.exe /select`, "效果%效果编号%.ahk"
  }
  else
  {
    Gui +OwnDialogs
    MsgBox 0x10, , 导出失败！`n`n%目标图片% 不存在。
  }
return

GuiEscape:
GuiClose:
  FileDelete, ocr_vis.png
  FileDelete, ocr_vis2.png
  ExitApp
return

WM_ACTIVATE(wParam) ; 失去焦点则关闭提示框
{
  if (wParam & 0xFFFF = 0)
  {
    btt(,,, 1)
  }
}

WM_MOUSEMOVE()
{
  switch, A_GuiControl
  {
    case "fast_model":
    说明=
    (LTrim
      是否使用更快速但准确率不高的模型。
    )
    
    case "use_mkldnn":
    说明=
    (LTrim
      是否使用 mkldnn 库（ CPU 加速用）。
    )
    
    case "cpu_math_library_num_threads":
    说明=
    (LTrim
      CPU 预测时的线程数。在机器核数充足的情况下，该值越大，预测速度越快。
      默认值为10。
    )
    
    case "use_polygon_score":
    说明=
    (LTrim
      是否使用多边形框。矩形框计算速度更快，多边形框对弯曲文本区域计算更准确。
    )
    
    case "max_side_len":
    说明=
    (LTrim
      输入图像长宽大于此值时，等比例缩放图像，使得图像最长边为此值。
      默认值为960。
    )
    
    case "det_db_thresh":
    说明=
    (LTrim
      用于过滤 DB 预测的二值化图像。设置为 0. - 0.3 对结果影响不明显。
      默认值为0.5。
    )
    
    case "det_db_box_thresh":
    说明=
    (LTrim
      DB 后处理过滤 box 的阈值。如果检测存在漏框情况，可酌情减小。
      默认值为0.5。
    )
    
    case "det_db_unclip_ratio":
    说明=
    (LTrim
      表示文本框的紧致程度。越小则文本框更靠近文本。
      默认值为2.2。
    )
    
    case "use_angle_cls":
    说明=
    (LTrim
      是否使用方向分类器。
    )
    
    case "cls_thresh":
    说明=
    (LTrim
      方向分类器的得分阈值。
      默认值为0.9。
    )
    
    case "use_tensorrt":
    说明=
    (LTrim
      是否使用 tensorrt 。
    )
    
    case "use_fp16":
    说明=
    (LTrim
      是否使用 fp16 。
    )
  }
  btt(说明,,,, "Style2")
}

GuiDefaultFont() { ; by SKAN (modified by just me)
   VarSetCapacity(LF, szLF := 28 + (A_IsUnicode ? 64 : 32), 0) ; LOGFONT structure
   If DllCall("GetObject", "Ptr", DllCall("GetStockObject", "Int", 17, "Ptr"), "Int", szLF, "Ptr", &LF)
      return {Name: StrGet(&LF + 28, 32), Size: Round(Abs(NumGet(LF, 0, "Int")) * (72 / A_ScreenDPI), 1)
            , Weight: NumGet(LF, 16, "Int"), Quality: NumGet(LF, 26, "UChar")}
   return False
}

#Include %A_LineFile%\..\PaddleOCR\PaddleOCR.ahk
#Include <Fnt>
#Include <Edit>
#Include <BTT>