// GameScene.swift
// Pterodactyl
//
//
//  Created by Richard Groeneveld on 1/17/23.
//  Based on code by Pierre-Henry Soria
//  https://github.com/pH-7/Flappy-Canary

import SpriteKit
import GameplayKit
import AVFoundation

let defaults = UserDefaults.standard

class GameScene: SKScene, SKPhysicsContactDelegate {
    let birdTimePerFrame = 0.1
    let maxTimeBgMoving: CGFloat = 3
    let bgAnimatedInSecs: TimeInterval = 7
    // Create a variable with Get and Set methods that will run when the variable is requested or changed

    var highScore:Int{
        get {
            // Get the standard UserDefaults as "defaults"
            let defaults = UserDefaults.standard
            
            // Makes the "welcomeString" variable whatever the saved value for "welcome_string" is
            return defaults.integer(forKey: "Best")
        }
        set (newValue) {
            // Get the standard UserDefaults as "defaults"
            let defaults = UserDefaults.standard
            
            // Saves what the highScore variable was just set to as the saved value for "Best"
            defaults.set(newValue, forKey: "Best")
        }
    }
    var bird: SKSpriteNode = SKSpriteNode()
    var background: SKSpriteNode = SKSpriteNode()
    var scoreLabel: SKLabelNode = SKLabelNode()
    var scoreTitleLabel: SKLabelNode = SKLabelNode()
    var highScoreLabel: SKLabelNode = SKLabelNode()
    var score: Int = 0
    var gameOver: Bool = false
    var StartScreen: Bool = true
    var gameOverLabel: SKLabelNode = SKLabelNode()
    var gameBeginLabel: SKLabelNode = SKLabelNode()
    var titleLabel: SKLabelNode = SKLabelNode()
    var instructionsLabel: SKLabelNode = SKLabelNode()
    var timer: Timer = Timer()
    var backgroundcounter: Int = Int.random(in: 1..<6)
    var audioPlayer : AVPlayer!
    
    

    enum ColliderType: UInt32 {
        case Bird = 1
        case Object = 2
        case Gap = 4
    }

    override func didMove(to view: SKView) -> Void {
        self.physicsWorld.contactDelegate = self
        initializeGame()
    }

    func initializeGame() -> Void {
        timer = Timer.scheduledTimer(
            timeInterval: 3,
             target: self,
             selector: #selector(self.drawPipes),
             userInfo: nil,
             repeats: true
        )
        backgroundcounter = Int.random(in: 1..<6)
        drawBackground()
        drawBird()
        drawPipes()
    }
    func playFlap() {
        guard let url = Bundle.main.url(forResource: "flap", withExtension: "mp3") else {
            print("error to get the mp3 file")
            return
        }
        
        do {
            audioPlayer = AVPlayer(url: url)
        }
        audioPlayer?.play()
    }
    
    func playCrash() {
        guard let url = Bundle.main.url(forResource: "birdcrash", withExtension: "mp3") else {
            print("error to get the mp3 file")
            return
        }
        
        do {
            audioPlayer = AVPlayer(url: url)
        }
        audioPlayer?.play()
    }
    
    func drawBird() -> Void {
        let birdTexture = SKTexture(imageNamed: "canary1.png")
        let birdTexture2 = SKTexture(imageNamed: "canary2.png")

        let animation = SKAction.animate(with: [birdTexture, birdTexture2], timePerFrame: birdTimePerFrame)
        let makeBirdFlap = SKAction.repeatForever(animation)

        bird = SKSpriteNode(texture: birdTexture)

        bird.position = CGPoint(x: self.frame.midX, y: self.frame.midY)
        bird.run(makeBirdFlap)

        // For colisions
        bird.physicsBody = SKPhysicsBody(circleOfRadius: birdTexture.size().height / 2)

        bird.physicsBody!.isDynamic = false

        bird.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        bird.physicsBody!.categoryBitMask = ColliderType.Bird.rawValue
        bird.physicsBody!.collisionBitMask = ColliderType.Bird.rawValue

        self.addChild(bird)

        makeGround()

        self.setScoreStyle()
        self.setScoreTitleStyle()
        self.setHighScoreStyle()
        self.setTitleStyle()
        self.setInstructionsStyle()
        
        scoreLabel.position = CGPoint(x: self.frame.midX + 200, y: self.frame.height / 2 - 210)
        self.addChild(scoreLabel)
        scoreTitleLabel.position = CGPoint(x: self.frame.midX + 200, y: self.frame.height / 2 - 150)
        self.addChild(scoreTitleLabel)
        highScoreLabel.position = CGPoint(x: self.frame.midX - 200, y: self.frame.height / 2 - 150)
        self.addChild(highScoreLabel)
        
        titleLabel.position = CGPoint(x: self.frame.midY, y: self.frame.midY-450)
        self.addChild(titleLabel)
        instructionsLabel.position = CGPoint(x: self.frame.midY, y: self.frame.midY-525)
        self.addChild(instructionsLabel)
    }
    
    func drawBackground() -> Void {
        let currentBackground = "background" + String(backgroundcounter) + ".png"
        let bgTexture = SKTexture(imageNamed: currentBackground)

        let moveBgAnimation = SKAction.move(by: CGVector(dx: -bgTexture.size().width, dy: 0), duration: bgAnimatedInSecs)
        let shiftBgAnimation = SKAction.move(by: CGVector(dx: bgTexture.size().width, dy: 0), duration: 0)
        let bgAnimation = SKAction.sequence([moveBgAnimation, shiftBgAnimation])
        let moveBgForever = SKAction.repeatForever(bgAnimation)

        var i: CGFloat = 0

        while i < maxTimeBgMoving {
            background = SKSpriteNode(texture: bgTexture)
            background.position = CGPoint(x: bgTexture.size().width * i, y: self.frame.midY)
            background.size.height = self.frame.height
            background.run(moveBgForever)

            self.addChild(background)

            i += 1

            // Set background first
            background.zPosition = -2
        }
    }

    // Draws the pipes and move them around the bird
    @objc func drawPipes() -> Void {
        let multiplier = Int.random(in: 4..<8)
        let gapHeight = bird.size.height * CGFloat(multiplier)

        let movePipes = SKAction.move(
            by: CGVector(dx: -2 * self.frame.width, dy: 0),
            duration: TimeInterval(self.frame.width / 100)
        )

        let removePipes = SKAction.removeFromParent()

        let movementAmount = arc4random() % UInt32(self.frame.height / 2)
        let moveAndRemovePipes = SKAction.sequence([movePipes, removePipes])

        let pipeOffset = CGFloat(movementAmount) - self.frame.height / 4

        makePipe1(moveAndRemovePipes, gapHeight, pipeOffset)
        makePipe2(moveAndRemovePipes, gapHeight, pipeOffset)
        makeGap(moveAndRemovePipes, gapHeight, pipeOffset)
    }

    func didBegin(_ contact: SKPhysicsContact) -> Void {
        if gameOver == false {
            if contact.bodyA.categoryBitMask == ColliderType.Gap.rawValue ||
                contact.bodyB.categoryBitMask == ColliderType.Gap.rawValue {
                score += 1
                if score % 5 == 0{
                    if backgroundcounter > 5 {
                        backgroundcounter = Int.random(in: 1..<6)
                        drawBackground()
                    }
                    else{
                        backgroundcounter = Int.random(in: 1..<6)
                        drawBackground()
                    }
                }
                if score > highScore {
                    highScore = score
                }
                scoreLabel.text = String(score)
                highScoreLabel.text = "High Score: " + String(highScore)
                
            } else {
                playCrash()
                resetGame()
                setMessageScoreStyle()
                setGameBeginStyle()
                gameOverLabel.text = "Game Over!"
                gameOverLabel.position = CGPoint(x: self.frame.midY, y: self.frame.midY)

                self.addChild(gameOverLabel)
                gameBeginLabel.text = "Touch screen to restart!"
                gameBeginLabel.position = CGPoint(x: self.frame.midY, y: self.frame.midY-300)
                self.addChild(gameBeginLabel)
                
            }
        }
    }

    func makePipe1(_ moveAndRemovePipes: SKAction, _ gapHeight: CGFloat, _ pipeOffset: CGFloat) -> Void {
        let pipeTexture = SKTexture(imageNamed: "pipe1.png")
        let pipe1 = SKSpriteNode(texture: pipeTexture)
        pipe1.position = CGPoint(
            x: self.frame.midX + self.frame.width,
            y: self.frame.midY + pipeTexture.size().height / 2 + gapHeight / 2 + pipeOffset
        )
        pipe1.run(moveAndRemovePipes)

        pipe1.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 65, height: 1650))
        pipe1.physicsBody!.isDynamic = false

        pipe1.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        pipe1.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        pipe1.physicsBody!.collisionBitMask = ColliderType.Object.rawValue
        setPipePosition(pipe1)

        self.addChild(pipe1)
    }

    func makePipe2(_ moveAndRemovePipes: SKAction, _ gapHeight: CGFloat, _ pipeOffset: CGFloat) -> Void {
        let pipe2Texture = SKTexture(imageNamed: "pipe2.png")
        let pipe2 = SKSpriteNode(texture: pipe2Texture)
        pipe2.position = CGPoint(
            x: self.frame.midX + self.frame.width,
            y: self.frame.midY - pipe2Texture.size().height / 2 - gapHeight / 2  + pipeOffset
        )
        pipe2.run(moveAndRemovePipes)

        pipe2.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: 65, height: 1650))
        pipe2.physicsBody!.isDynamic = false

        pipe2.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        pipe2.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        pipe2.physicsBody!.collisionBitMask = ColliderType.Object.rawValue
        setPipePosition(pipe2)

        self.addChild(pipe2)
    }

    // Set the pipe second position after background
    func setPipePosition(_ pipe: SKSpriteNode) -> Void {
        pipe.zPosition = -1
    }

    func makeGap(_ moveAndRemovePipes: SKAction, _ gapHeight: CGFloat, _ pipeOffset: CGFloat) -> Void {
        let pipeTexture = SKTexture(imageNamed: "pipe1.png")

        let gap = SKNode()
        gap.position = CGPoint(x: self.frame.midX + self.frame.width, y: self.frame.midY + pipeOffset)
        gap.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: pipeTexture.size().width, height: gapHeight))

        gap.physicsBody!.isDynamic = false
        gap.run(moveAndRemovePipes)

        gap.physicsBody!.contactTestBitMask = ColliderType.Bird.rawValue
        gap.physicsBody!.categoryBitMask = ColliderType.Gap.rawValue
        gap.physicsBody!.collisionBitMask = ColliderType.Gap.rawValue

        self.addChild(gap)
    }

    func makeGround() -> Void {
        let ground = SKNode()
        ground.position = CGPoint(x: self.frame.midX, y: -self.frame.height / 2)
        ground.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: self.frame.width, height: 1))

        ground.physicsBody!.isDynamic = false

        ground.physicsBody!.contactTestBitMask = ColliderType.Object.rawValue
        ground.physicsBody!.categoryBitMask = ColliderType.Object.rawValue
        ground.physicsBody!.collisionBitMask = ColliderType.Object.rawValue

        self.addChild(ground)
    }

    func setScoreStyle() -> Void {
        scoreLabel.fontName = "Helvetica"
        scoreLabel.fontSize = 80
        scoreLabel.text = "0"
    }
    func setScoreTitleStyle() -> Void {
        scoreTitleLabel.fontName = "Helvetica"
        scoreTitleLabel.fontSize = 30
        scoreTitleLabel.text = "Score"
    }
    func setHighScoreStyle() -> Void {
        highScoreLabel.fontName = "Helvetica"
        highScoreLabel.fontSize = 30
        highScoreLabel.text = "High Score: " + String(highScore)
        highScoreLabel.fontColor = UIColor(red: 237255, green: 231/255, blue: 213/255, alpha: 255)
    }
    func setTitleStyle() -> Void {
        titleLabel.fontName = "Zapfino"
        titleLabel.fontSize = 40
        titleLabel.text = "Pterodactyl"
    }
    func setInstructionsStyle() -> Void {
        instructionsLabel.fontName = "Helvetica"
        instructionsLabel.fontSize = 30
        instructionsLabel.text = "Tap Screen to Play"
        instructionsLabel.fontColor = UIColor(red: 237255, green: 231/255, blue: 213/255, alpha: 255)
    }
    func setMessageScoreStyle() -> Void {
        gameOverLabel.fontName = "Helvetica"
        gameOverLabel.fontSize = 60
        gameOverLabel.fontColor = UIColor(red: 255, green: 0, blue: 0, alpha: 255)
    }
    func setGameBeginStyle() -> Void {
        gameBeginLabel.fontName = "TrebuchetMS-Italic"
        gameBeginLabel.fontSize = 30
    }

    override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) -> Void {
        if gameOver == false {
            bird.physicsBody!.isDynamic = true
            bird.physicsBody!.velocity = CGVector(dx: 0, dy: 0)
            bird.physicsBody!.applyImpulse(CGVector(dx: 0, dy: 60))
            playFlap()
        } else {
            startGame()
            removeAllChildren()
            StartScreen = false
            initializeGame()
        }
    }

    func startGame() -> Void {
        gameOver = false
        score = 0
        self.speed = 1
    }

    func resetGame() -> Void {
        self.speed = 0
        gameOver = true
        timer.invalidate()
    }
}

