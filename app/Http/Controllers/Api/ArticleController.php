<?php

namespace App\Http\Controllers\Api;

use App\Http\Controllers\Controller;
use App\Http\Requests\Api\VoteRequest;
use App\Http\Requests\ArticleRequest;
use App\Http\Resources\ArticleResource;
use App\Http\Resources\ArticlesResource;
use App\Models\Article;
use App\Models\User;
use Exception;
use Illuminate\Http\JsonResponse;
use Ramsey\Uuid\Uuid;
use Str;
use Throwable;

class ArticleController extends Controller
{
    /**
     * Display a listing of the resource.
     *
     * @return ArticlesResource
     */
    public function index(): ArticlesResource
    {
        $articles = Article::with(
            [
                'creator' => function ($query) {
                    $query->select('id', 'username', 'avatar', 'description', 'karma', 'rating')->withCount(
                        'articles',
                        'followers'
                    );
                },
            ]
        )->withcount(
            'views',
        )->orderBy(
            'created_at',
            'DESC'
        )->take(50)->paginate(5);

        return new ArticlesResource($articles);
    }

    /**
     * Display the specified resource.
     *
     * @param $id
     *
     * @return ArticleResource
     */
    public function show($id): ArticleResource
    {
        ArticleResource::withoutWrapping();

        return new ArticleResource(
            Article::withcount(
                'views',
            )->findOrFail($id)
        );
    }

    public function store(ArticleRequest $request): JsonResponse
    {
        try {
            $article = Article::create(
                [
                    'id'        => Uuid::uuid4(),
                    'name'      => $request->title,
                    'slug'      => Str::slug($request->title),
                    'content'   => $request->body,
                    'author_id' => $request->user()->id,
                ]
            );
            $article->hubs()->sync($request->hubs);

            return new JsonResponse($article->slug);
        } catch (Exception $exception) {
            report($exception);

            return new JsonResponse($exception->getMessage(), 500);
        }
    }

    /**
     * @param VoteRequest $request
     * @return JsonResponse
     * @throws Throwable
     */
    public function vote(VoteRequest $request): JsonResponse
    {
        $user = auth()->user();

        $article = Article::findOrFail($request->id);
        ($request->type === 'up') ? User::upOrDownVote($user, $article) : User::upOrDownVote($user, $article, 'down');

        return response()->json(['success' => 'success',]);
    }
}
