//
//  SoundLevelMonitor.swift
//  ToDivers-iOS
//
//  Created by Neon on 3/26/26.
//

import SwiftUI

import AVFoundation
import Combine

class SoundLevelMonitor: ObservableObject {
    
    private var audioEngine = AVAudioEngine()
    private var isMonitoring = false
    
    /// 현재 소리 크기 상태값
    @Published var decibels: Float = 0.0
    
    func startMonitoring() {
        /// 재진입 방지
        guard !isMonitoring else { return }
        
        /// 마이크 입력
        let inputNode = audioEngine.inputNode
        let format = inputNode.outputFormat(forBus: 0)
        
        inputNode.installTap(onBus: 0, bufferSize: 1024, format: format) { [weak self] buffer, _ in
            guard let self else { return }
            
            let level = self.getSoundLevel(buffer: buffer) // buffer 크기 계산
            DispatchQueue.main.async {
                self.decibels = self.decibels * 0.8 + level * 0.2 // 데시벨 업데이트
            }
        }
        
        do {
            try audioEngine.start()
            isMonitoring = true
        } catch {
            print("AudioEngine start failed:", error)
        }
    }
    
    func stopMonitoring() {
        guard isMonitoring else { return }
        audioEngine.stop()
        audioEngine.inputNode.removeTap(onBus: 0)
        isMonitoring = false
    }
    
    private func getSoundLevel(buffer: AVAudioPCMBuffer) -> Float {
        guard let channelData = buffer.floatChannelData else { return 0 } // 실제 오디오 파형
        
        let channelDataArray = Array(UnsafeBufferPointer(start: channelData[0], count: Int(buffer.frameLength)))
        
        /// 소리의 에너지 크기 계산
        let rms = sqrt(channelDataArray.map { $0 * $0 }.reduce(0,+) / Float(buffer.frameLength) + Float.ulpOfOne)
        let level = 20 * log10(rms) // 로그 스케일로 변환
        return max(level + 100, 0) // 값 보정
    }
}
