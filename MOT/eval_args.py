from absl import app
from absl import flags
import evalMOT

FLAGS = flags.FLAGS

flags.DEFINE_string('benchmark_name', 'MOT17', 'Challenge name.')
flags.DEFINE_string('gt_dir', 'data', 'Directory that contains train/ and test/')
flags.DEFINE_string('eval_mode', 'train', 'Which subset, train or test.')
flags.DEFINE_string('res_dir', None, 'Directory containing predictions of one tracker.')
flags.DEFINE_string('save_pkl', None, 'Where to save results.')
flags.DEFINE_string('seqmaps_dir', 'seqmaps', 'Challenge to evaluate.')


def main(_):
    evaluator = evalMOT.MOT_evaluator()
    evaluator.run(benchmark_name=FLAGS.benchmark_name,
                  gt_dir=FLAGS.gt_dir,
                  res_dir=FLAGS.res_dir,
                  save_pkl=FLAGS.save_pkl,
                  eval_mode=FLAGS.eval_mode,
                  seqmaps_dir=FLAGS.seqmaps_dir)


if __name__ == '__main__':
    flags.mark_flag_as_required('res_dir')
    app.run(main)
