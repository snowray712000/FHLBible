//
//  VCAudioTextSpeed.swift
//  FHLBible
//
//  Created by littlesnow on 2023/6/2.
//

import Foundation
import UIKit
import AVFoundation

class VCAudioTextSpeed : UIViewController {
    @IBOutlet var sliders: [UISlider]!
    @IBOutlet var labelSpeeds: [UILabel]!
    deinit {
        if synthesizer.isSpeaking {
            synthesizer.stopSpeaking(at: .immediate)
        }
    }
    override func viewDidLoad() {
        super.viewDidLoad()
        
        func init_slider(_ slider: UISlider){
            slider.isContinuous = false
            slider.addTarget(self, action: #selector(sliderValueChanged), for: .valueChanged)
            
            let tapGestureRecognizer = UITapGestureRecognizer(target: self, action: #selector(handleTap(_:)))
            tapGestureRecognizer.numberOfTapsRequired = 1
            slider.addGestureRecognizer(tapGestureRecognizer)
        }
     
        for a1 in sliders{
            init_slider(a1)
        }
        
        // speed label and slider update
        let speeds = self.speeds
        for idx in ijnRange(0, speeds.count){
            let speed = speeds[idx]
            let str = speed2string(speed)
            self.labelSpeeds[idx].text = "x" + str
            self.sliders[idx].value = speed2value(speed)
        }
    }
    var speeds: [Float] {
        get {
            return ManagerAudioTextSpeed.s.curSpeed
        }
        set {
            ManagerAudioTextSpeed.s.updateSpeed(newValue)
        }
    }
    @objc func sliderValueChanged(_ sender: UISlider) {
        let value = Int(sender.value)
        if let idx = ijnRange(0, self.sliders.count).first(where: {self.sliders[$0]==sender}){
            let speed = value2speed(value)
            let str = speed2string(speed)
            self.labelSpeeds[idx].text = "x" + str
            self.playSample(idx, speed)
            
            // update global speed
            self.speeds[idx] = speed
        }
    }
    @objc func handleTap(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let slider = gestureRecognizer.view as? UISlider else {
            return
        }
        
        let point = gestureRecognizer.location(in: slider)
        let value = Int(slider.value)
        
        if point.x < slider.bounds.width / 2 {
            // 左邊點擊
            if value > Int(slider.minimumValue) {
                slider.value -= 1
                sliderValueChanged(slider)
            }
        } else {
            // 右邊點擊
            if value < Int(slider.maximumValue) {
                slider.value += 1
                sliderValueChanged(slider)
            }
        }
    }
    func value2speed(_ i:Int) -> Float {
        // 0: 0.25 1: 0.50 2: 0.75 3:1.0 4: 1.25 5: 1.50 1.75 2.00
        return (Float(i) + 1.0) * 0.25
    }
    func speed2value(_ v:Float)-> Float{
        return v / 0.25 - 1
    }
    func speed2string(_ v:Float)->String{
        return String(format: "%.2f", v)
    }
    let synthesizer = AVSpeechSynthesizer()
    func playSample(_ i:Int,_ speed:Float){
        func getData()->String{
            switch i {
            case 0:
                return ManagerLangSet.s.curIsGb ? TTSEngineSamples.zhCN : TTSEngineSamples.zhTW
            case 1:
                return TTSEngineSamples.enUS
            case 2:
                return TTSEngineSamples.hebrew
            case 3:
                return TTSEngineSamples.greek
            case 4:
                return TTSEngineSamples.jp
            case 5:
                return TTSEngineSamples.korean
            case 6:
                return TTSEngineSamples.viVN
            case 7:
                return TTSEngineSamples.ru
            default:
                return ""
            }
        }
        func getEngine()->AVSpeechSynthesisVoice? {
            switch i {
            case 0:
                return ManagerLangSet.s.curIsGb ? TTSEngineGetter.zhCN : TTSEngineGetter.zhTW
            case 1:
                return TTSEngineGetter.enUS
            case 2:
                return TTSEngineGetter.hebrew
            case 3:
                return TTSEngineGetter.greek
            case 4:
                return TTSEngineGetter.jp
            case 5:
                return TTSEngineGetter.korean
            case 6:
                return TTSEngineGetter.viVN
            case 7:
                return TTSEngineGetter.ru
            default:
                return nil
            }
        }
        
        if let tts = getEngine() {
            if synthesizer.isSpeaking {
                synthesizer.stopSpeaking(at: .immediate)
            }
            let r1 = AVSpeechUtterance(string: getData())
            r1.voice = tts
            r1.rate = 0.5 * speed
            synthesizer.speak(r1)
        }
    }
}
