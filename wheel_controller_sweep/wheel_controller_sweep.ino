// Pins
#define START_TRIALS 52
#define ENC_A 2 // Needs to be an interrupt pin
#define ENC_B 3 // Needs to be an interrupt pin
#define ENC_I 4 // Not actually used

#define SCOPE_OUT 23
#define TRIAL_OUT 25
#define CS_OUT 27
#define US_OUT 29

// Encoder counters
volatile int steps_fwd = 0;
volatile int steps_bwd = 0;

// Behavioral parameters
#define SCOPE_PRE 2000  // Turn on scope prior to trial start, ms
#define SCOPE_POST 2000 // Turn off scope after trial start
#define CS_DURATION 6000 // ms
#define CS_GRACE 2500 // ms
#define ITI_MIN 25000 // ms
#define ITI_MAX 35000 // ms

#define CS_POLL_RATE 500 // ms
#define THRESHOLD_STEPS 40 // Corresponds to 5 cm/s over 0.5 sec

// FSM definitions
#define S_IDLE 0
#define S_PRE 1
#define S_BEGIN_TRIAL 2
#define S_CS 3
#define S_END_TRIAL 5
#define S_POST 6
#define S_ITI 7

int state = S_IDLE;
int cs_elapsed_time;
bool enable_cs;
bool enable_us;

void setup() {
  // put your setup code here, to run once:
  pinMode(START_TRIALS, INPUT_PULLUP);
  pinMode(ENC_A, INPUT);
  attachInterrupt(digitalPinToInterrupt(ENC_A), count_A, RISING);
  pinMode(ENC_B, INPUT);
  pinMode(ENC_I, INPUT);

  pinMode(SCOPE_OUT, OUTPUT);
  pinMode(TRIAL_OUT, OUTPUT);
  pinMode(CS_OUT, OUTPUT);
  pinMode(US_OUT, OUTPUT);
  
  state = S_IDLE;
}

void count_A() {
  if (digitalRead(ENC_B))
    steps_fwd++;
  else
    steps_bwd++;
}

void loop() {
  bool trials_enabled = digitalRead(START_TRIALS);
  if (!trials_enabled) {
    // Controller should be disabled
    digitalWrite(SCOPE_OUT, 0);
    digitalWrite(TRIAL_OUT, 0);
    digitalWrite(CS_OUT, 0);
    digitalWrite(US_OUT, 0);
 
    state = S_IDLE;
  }
  else {
    // Implement FSM
    switch (state) {
      case S_IDLE:
        // After the START_TRIALS signals is given, wait 2 sec prior
        // to launching trials
        delay(2000);
        state = S_PRE;
        break;
        
      case S_PRE:
        digitalWrite(SCOPE_OUT, 1);
        delay(SCOPE_PRE);
        state = S_BEGIN_TRIAL;
        break;

      case S_BEGIN_TRIAL:
        digitalWrite(TRIAL_OUT, 1);
        state = S_CS;
        break;

      case S_CS:
        enable_cs = true;
        enable_us = true;
        cs_elapsed_time = 0;
        
        while (cs_elapsed_time < CS_DURATION) {
          digitalWrite(CS_OUT, enable_cs);
          digitalWrite(US_OUT, (cs_elapsed_time > CS_GRACE) && enable_us);
          
          steps_fwd = 0;
          steps_bwd = 0;
          delay(CS_POLL_RATE);
          if (steps_fwd - steps_bwd > THRESHOLD_STEPS) {
            enable_cs = false;
            enable_us = false;
          }
          
          cs_elapsed_time += CS_POLL_RATE; 
        }
        state = S_END_TRIAL;
        break;

      case S_END_TRIAL:
        digitalWrite(US_OUT, 0);
        digitalWrite(CS_OUT, 0);
        digitalWrite(TRIAL_OUT, 0);
        state = S_POST;
        break;

      case S_POST:
        delay(SCOPE_POST);
        digitalWrite(SCOPE_OUT, 0);
        state = S_ITI;
        break;

      case S_ITI:
        // ITI defined as time between _behavioral_ trials
        delay(random(ITI_MIN, ITI_MAX) - (SCOPE_PRE+SCOPE_POST));
        state = S_PRE;
        break;
 
      default:
        state = S_IDLE;
    }
  }
}
