pipeline {
    agent {
        dockerfile true
    }
    environment {
        CI            = 'true'
        PRJ_COMMITS   = """${sh(
            returnStdout: true,
            script: 'git shortlog -s -n --all | grep -oP "^\\s+\\d+\\s+" | xargs | tr " " "+" | bc'
        ).trim()}"""
    }
    stages {
        stage('Compiling') {
            steps {
                sh 'kolchan-automake'
            }
        }
        stage('Testing') {
            steps {
                sh '_bashlyk_pathLib=src/ src/bashlyk --bashlyk-test=std,err,pid,net,msg'
            }
        }
        stage('prepare new version of package') {
            steps {
                sh 'kolchan-up2deb'
            }
        }
        stage('Build debian package locally') {
            steps {
                sh 'kolchan-builddeb'
            }
        }
        stage('Deploy to launchpad.net') {
           steps {
                sh 'kolchan-builddeb --mode source'
            }
        }
    }
}
