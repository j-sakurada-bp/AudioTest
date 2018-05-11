//
//  ViewController.swift
//  AudioTest
//
//  Created by Jun Sakurada on 2018/05/08.
//  Copyright © 2018年 Jun Sakurada. All rights reserved.
//

import UIKit
import AVFoundation
import MediaPlayer

class ViewController: UIViewController, AVAudioPlayerDelegate {

    @IBOutlet weak var viewDeviceVolume: UIView!
    @IBOutlet weak var sldH1: UISlider!
    @IBOutlet weak var sldMozart: UISlider!
    @IBOutlet weak var sldAnime: UISlider!
    @IBOutlet weak var sldJingle: UISlider!
    @IBOutlet weak var sldDeviceVolume: UISlider!
    
    public var player1: AVAudioPlayer?
    public var player2: AVAudioPlayer?
    public var player3: AVAudioPlayer?
    public var playerJingle: AVAudioPlayer?
    
    internal let audioSession = AVAudioSession.sharedInstance()
    
    var volumeSlider: UISlider!
    var vol: Float?
    
    override func viewDidLoad() {
        super.viewDidLoad()
        observeSystemVolume()
        
        sldDeviceVolume.isHidden = true
        
        let mpVolumeView = MPVolumeView(frame: self.viewDeviceVolume.bounds)
//        mpVolumeView.isHidden = true
        self.viewDeviceVolume.addSubview(mpVolumeView)
        for childView in mpVolumeView.subviews {
            if (childView.isKind(of: UISlider.self)) {
                self.volumeSlider = childView as! UISlider
            }
        }
    }
    
    override func viewDidDisappear(_ animated: Bool) {
        super.viewDidDisappear(animated)
        audioSession.removeObserver(self, forKeyPath: "outputVolume")
    }
    
    override func didReceiveMemoryWarning() {
        super.didReceiveMemoryWarning()
    }
    
    //MARK: - UIButtonイベントハンドラ
    
    /// 花咲爺さんスタートボタン
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func btnH1StartTapped(_ sender: UIButton) {
        let volume: Float = 1.0
        playH1(volume)
        sldH1.value = volume
    }
    
    /// モーツァルトスタートボタン
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func btnMozartStartTapped(_ sender: UIButton) {
        let volume: Float = 1.0
        playEine(volume)
        sldMozart.value = volume
    }
    
    /// アニメーション風スタートボタン
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func btnAnimeStartTapped(_ sender: UIButton) {
        let volume: Float = 1.0
        playAnime(volume)
        sldAnime.value = volume
    }
    
    /// 花咲爺さんストップボタン
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func btnH1StopTapped(_ sender: UIButton) {
        player1?.stop()
    }
    
    /// モーツァルトストップボタン
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func btnMozartStopTapped(_ sender: UIButton) {
        player2?.stop()
    }
    
    /// アニメーション風ストップボタン
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func btnAnimeStopTapped(_ sender: UIButton) {
        player3?.stop()
    }
    
    /// ジングルストップボタン
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func btnJingleTapped(_ sender: UIButton) {
        let volume: Float = sldJingle.value
        lowerOtherVolume()
        playJingle(volume)
    }
    
    //MARK: - UISliderイベントハンドラ
    
    /// 花咲爺さん音量スライダー
    ///
    /// - Parameter sender:
    @IBAction func sldH1Changed(_ sender: UISlider) {
        guard let player = player1 else {
            print("PLAYER1 NOT CREATED.")
            return
        }
        player.volume = sender.value
    }
    
    /// モーツァルト音量スライダー
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func sldMozartChanged(_ sender: UISlider) {
        guard let player = player2 else {
            print("PLAYER2 NOT CREATED.")
            return
        }
        player.volume = sender.value
    }
    
    /// アニメーション風音量スライダー
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func sldAnimeChanged(_ sender: UISlider) {
        guard let player = player3 else {
            print("PLAYER3 NOT CREATED.")
            return
        }
        player.volume = sender.value
    }
    
    /// ジングル音量スライダー
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func sldJingleChanged(_ sender: UISlider) {
        
    }
    
    /// iOS音量スライダー
    ///
    /// - Parameter sender: <#sender description#>
    @IBAction func sldDeviceVolumeChanged(_ sender: UISlider) {
        
        print(sender.value)
        try! audioSession.setInputGain(sender.value)
        try! audioSession.setActive(true)
    }

    //MARK: -
    
    /// iOS端末のボリュームを下げる。
    /// 現在、半分に下げている。
    internal func lowerOtherVolume() {
        
        vol = self.volumeSlider.value
        self.volumeSlider.setValue(vol! / 2, animated: false)
    }
    
    /// AVAudioSessionに出力ボリューム変更イベントハンドラを設定する。
    internal func observeSystemVolume() {
        
        try! audioSession.setCategory(AVAudioSessionCategoryPlayAndRecord)
        try! audioSession.setActive(true)
        
        audioSession.addObserver(self,
                                 forKeyPath: "outputVolume",
                                 options: [ .new ],
                                 context: nil)
    }
    
    /// iOS端末のボリューム操作を監視する。
    /// ボリュームスライダーと端末のボリュームを同期する。
    ///
    /// - Parameters:
    ///   - keyPath: <#keyPath description#>
    ///   - object: <#object description#>
    ///   - change: <#change description#>
    ///   - context: <#context description#>
    override func observeValue(forKeyPath keyPath: String?,
                               of object: Any?,
                               change: [NSKeyValueChangeKey : Any]?,
                               context: UnsafeMutableRawPointer?) {
        	
        print(audioSession.outputVolume)
        sldDeviceVolume.setValue(audioSession.outputVolume, animated: false)
    }
    
    /// 花咲爺さん音源を再生する。
    ///
    /// - Parameter volume: <#volume description#>
    internal func playH1(_ volume: Float) {
        guard let sound_h1 = NSDataAsset(name: "h1") else {
            return
        }
        player1 = try? AVAudioPlayer(data: sound_h1.data)
        player1?.setVolume(volume, fadeDuration: 0)
        player1?.play()
    }
    
    /// モーツァルト音源を再生する。
    ///
    /// - Parameter volume: <#volume description#>
    internal func playEine(_ volume: Float) {
        guard let sound_eine = NSDataAsset(name: "eine") else {
            return
        }
        player2 = try? AVAudioPlayer(data: sound_eine.data)
        player2?.setVolume(volume, fadeDuration: 0)
        player2?.play()
    }
    
    /// アニメーション風音源を再生する。
    ///
    /// - Parameter volume: <#volume description#>
    internal func playAnime(_ volume: Float) {
        guard let sound_ani = NSDataAsset(name: "ani") else {
            return
        }
        player3 = try? AVAudioPlayer(data: sound_ani.data)
        player3?.setVolume(volume, fadeDuration: 0)
        player3?.play()
    }
    
    /// ジングル音源を再生する。
    ///
    /// - Parameter volume: <#volume description#>
    internal func playJingle(_ volume: Float) {
        guard let jingle = NSDataAsset(name: "jingle") else {
            return
        }
        playerJingle = try? AVAudioPlayer(data: jingle.data)
        playerJingle?.setVolume(volume, fadeDuration: 0)
        // 再生終了/中断イベントハンドラを自身に設定
        playerJingle?.delegate = self
        playerJingle?.play()
    }
    
    
    /// 音声の再生が終了した時の処理。
    ///
    /// - Parameters:
    ///   - player: <#player description#>
    ///   - flag: <#flag description#>
    public func audioPlayerDidFinishPlaying(_ player: AVAudioPlayer, successfully flag: Bool) {
        restoreOtherVolume()
    }
    
    
    /// 音声の再生が中断された時の処理。
    ///
    /// - Parameters:
    ///   - player: <#player description#>
    ///   - flags: <#flags description#>
    public func audioPlayerEndInterruption(_ player: AVAudioPlayer, withOptions flags: Int) {
        restoreOtherVolume()
    }
    
    /// iOS端末全体のボリュームを元に戻す。
    internal func restoreOtherVolume() {
        self.volumeSlider.setValue(vol!, animated: false)
    }
}

